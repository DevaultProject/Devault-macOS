// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVCore

/// `ClipboardService`(pasteboard I/O)와 `SecurityNotificationService`(알림)를 조합해
/// 복사 후 30초 자동 정리, 반복 복사 시 비정상 접근 알림 정책을 구현한다.
/// 반복 판단 로직 자체는 `AbnormalAccessMonitor`(순수·테스트 가능)에 위임한다.
///
/// 알림 발송 실패는 복사 자체를 실패시키지 않는다 — 로깅만 하고 삼킨다.
public actor CopySensitiveValueUseCaseImpl: CopySensitiveValueUseCase {
    private static let abnormalAccessWindow: Duration = .seconds(60)
    private static let abnormalAccessThreshold = 5

    private let clipboardService: any ClipboardService
    private let notificationService: any SecurityNotificationService
    private let clipboardClearDelay: Duration
    private let now: @Sendable () -> ContinuousClock.Instant
    private let abnormalAccessMonitor = AbnormalAccessMonitor(
        window: abnormalAccessWindow,
        threshold: abnormalAccessThreshold
    )

    public init(
        clipboardService: any ClipboardService,
        notificationService: any SecurityNotificationService,
        clipboardClearDelay: Duration = .seconds(30),
        now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now }
    ) {
        self.clipboardService = clipboardService
        self.notificationService = notificationService
        self.clipboardClearDelay = clipboardClearDelay
        self.now = now
    }

    public func execute(_ value: String) async throws {
        // 이 changeCount를 기준점 삼아, 아래 백그라운드 Task에서 "그 사이 다른 값이 복사됐는지" 판단
        let changeCount = try clipboardService.write(value)

        // 알림 발송이 오래 걸려도 정리 시작 시점이 밀리지 않도록, 값을 쓰자마자 먼저 스케줄링한다.
        // execute()를 30초씩 붙잡아둘 수 없으므로 별도 Task로 분리, 필요한 값만 캡처해서 넘김
        Task { [clipboardService, notificationService, clipboardClearDelay] in
            try? await Task.sleep(for: clipboardClearDelay)
            // changeCount가 그대로면 방치된 것으로 보고 정리, 바뀌었으면 아무것도 하지 않음
            guard clipboardService.clearIfUnchanged(from: changeCount) else { return }
            do {
                let seconds = Int(clipboardClearDelay.components.seconds)
                try await notificationService.notify(.clipboardExceeded(seconds: seconds))
            } catch {
                Log.warn("클립보드 정리 알림 발송 실패: \(error)", category: .notification)
            }
        }

        // 반복 복사 알림 발송
        if abnormalAccessMonitor.recordAccess(at: now()) {
            do {
                try await notificationService.notify(
                    .abnormalAccess(kind: .repeatedCopy, threshold: Self.abnormalAccessThreshold)
                )
            } catch {
                // 알림 실패는 복사 자체를 실패시키면 안 되므로 로깅만
                Log.warn("비정상 접근 알림 발송 실패: \(error)", category: .notification)
            }
        }
    }
}
