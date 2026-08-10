// Copyright © 2026 Devault. All rights reserved

import AppKit
import Foundation

import DVCore
import DVDomain

/// 클립보드 복사 이후의 부가 동작(30초 자동 정리, 반복 복사 감지)을 담당한다.
/// 카운팅 로직 자체는 `AbnormalAccessMonitor`(순수·테스트 가능)에 위임하고,
/// 여기서는 NSPasteboard I/O와 타이밍만 다룬다.
///
/// 알림 발송 실패는 복사 자체를 실패시키지 않는다 — 로깅만 하고 삼킨다.
public actor ClipboardServiceImpl: ClipboardService {
    private static let clipboardClearDelay: Duration = .seconds(30)
    private static let abnormalAccessWindow: TimeInterval = 60
    private static let abnormalAccessThreshold = 5

    private let notificationService: any SecurityNotificationService
    private let abnormalAccessMonitor = AbnormalAccessMonitor(
        window: abnormalAccessWindow,
        threshold: abnormalAccessThreshold
    )

    public init(notificationService: any SecurityNotificationService) {
        self.notificationService = notificationService
    }

    public func copySensitiveValue(_ value: String) async throws {
        let pasteboard = NSPasteboard.general
        // clearContents()가 pasteboard 소유권을 이 프로세스로 가져오면서 changeCount를 증가시킴
        // 이후 changeCount를 그대로 기록해두면, 30초 뒤 이 값이 바뀌었는지만 비교해서 "그 사이 다른 값이 복사됐는지"를 판단 가능
        pasteboard.clearContents()
        guard pasteboard.setString(value, forType: .string) else {
            throw ClipboardError.writeFailed
        }
        let changeCount = pasteboard.changeCount

        if abnormalAccessMonitor.recordAccess(at: Date()) {
            do {
                try await notificationService.notify(
                    .abnormalAccess(reason: "짧은 시간 안에 값 복사가 \(Self.abnormalAccessThreshold)회 이상 반복됨")
                )
            } catch {
                Log.warn("비정상 접근 알림 발송 실패: \(error)", category: .notification)
            }
        }

        Task { [notificationService] in
            try? await Task.sleep(for: Self.clipboardClearDelay)
            // changeCount가 그대로면 30초 동안 아무도 pasteboard를 건드리지 않았다는 뜻 — 안전하게 정리
            // 바뀌었다면 사용자가 이미 다른 값을 복사한 것이므로 건드리지 않음
            guard NSPasteboard.general.changeCount == changeCount else { return }
            NSPasteboard.general.clearContents()
            do {
                try await notificationService.notify(.clipboardExceeded(seconds: 30))
            } catch {
                Log.warn("클립보드 정리 알림 발송 실패: \(error)", category: .notification)
            }
        }
    }
}
