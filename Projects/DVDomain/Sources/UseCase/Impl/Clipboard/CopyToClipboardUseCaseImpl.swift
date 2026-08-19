// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVCore

/// `ClipboardService`(pasteboard I/O)와 `SecurityNotificationService`(알림)를 조합해
/// 복사 인증, 자동 정리, 반복 복사 알림을 수행한다. 각 정책은 `ClipboardCopyPolicy`가 참여를
/// 허용하고 설정도 켜져 있을 때만 동작하며, 반복 판단 자체는 `AbnormalAccessMonitor`에 위임한다.
///
/// 알림 발송 실패는 복사 자체를 실패시키지 않는다 — 로깅만 하고 삼킨다.
public actor CopyToClipboardUseCaseImpl: CopyToClipboardUseCase {
    private let clipboardService: any ClipboardService
    private let notificationService: any SecurityNotificationService
    private let authenticateUseCase: any AuthenticateUseCase
    private let settingsRepository: any SettingsRepository
    private let abnormalAccessThreshold: Int
    private let abnormalAccessMonitor: AbnormalAccessMonitor
    private let now: @Sendable () -> ContinuousClock.Instant
    private let sleep: @Sendable (Duration) async throws -> Void

    /// - Parameters:
    ///   - abnormalAccessWindow: 반복 복사로 볼 시간 범위
    ///   - abnormalAccessThreshold: 그 안에서 몇 번째 복사부터 비정상으로 볼지
    public init(
        clipboardService: any ClipboardService,
        notificationService: any SecurityNotificationService,
        authenticateUseCase: any AuthenticateUseCase,
        settingsRepository: any SettingsRepository,
        abnormalAccessWindow: Duration,
        abnormalAccessThreshold: Int,
        now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now },
        sleep: @escaping @Sendable (Duration) async throws -> Void = {
            try await Task.sleep(for: $0)
        }
    ) {
        self.clipboardService = clipboardService
        self.notificationService = notificationService
        self.authenticateUseCase = authenticateUseCase
        self.settingsRepository = settingsRepository
        self.abnormalAccessThreshold = abnormalAccessThreshold
        self.abnormalAccessMonitor = AbnormalAccessMonitor(
            window: abnormalAccessWindow,
            threshold: abnormalAccessThreshold
        )
        self.now = now
        self.sleep = sleep
    }

    public func execute(_ value: String, policy: ClipboardCopyPolicy) async throws {
        try await authenticateIfNeeded(policy)
        // 이 changeCount를 기준점 삼아 "그 사이 다른 값이 복사됐는지" 판단한다.
        let changeCount = try clipboardService.write(value)
        scheduleAutoClear(from: changeCount, policy: policy)
        await notifyIfRepeated(policy)
    }
}

private extension CopyToClipboardUseCaseImpl {

    func authenticateIfNeeded(_ policy: ClipboardCopyPolicy) async throws {
        guard policy.requiresAuthentication,
              settingsRepository.isRequireAuthToCopyEnabled() else { return }
        try await authenticateUseCase.authenticate(reason: .copySecret)
    }

    /// 알림 발송이 오래 걸려도 정리 시작 시점이 밀리지 않도록 값을 쓴 직후에 부른다.
    /// `execute()`를 설정 시간만큼 붙잡아둘 수 없어 별도 Task로 분리하고 필요한 값만 캡처한다.
    func scheduleAutoClear(from changeCount: Int, policy: ClipboardCopyPolicy) {
        guard policy.participatesInAutoClear,
              settingsRepository.isAutoClearClipboardEnabled() else { return }

        let delay = Duration.seconds(settingsRepository.autoClearClipboardDelaySeconds())
        let sleep = self.sleep
        Task { [clipboardService, notificationService, sleep] in
            do {
                try await sleep(delay)
            } catch {
                return
            }
            // changeCount가 그대로면 방치된 것으로 보고 정리, 바뀌었으면 아무것도 하지 않음
            guard clipboardService.clearIfUnchanged(from: changeCount) else { return }
            do {
                let seconds = Int(delay.components.seconds)
                try await notificationService.notify(.clipboardExceeded(seconds: seconds))
            } catch {
                Log.warn("클립보드 정리 알림 발송 실패: \(error)", category: .notification)
            }
        }
    }

    /// 참여하지 않는 복사는 알림뿐 아니라 **기록 자체를 건너뛴다**. 카운터에 쌓아두면 이어지는
    /// 민감 값 복사 한 번이 임계값을 넘겨 오탐이 난다.
    func notifyIfRepeated(_ policy: ClipboardCopyPolicy) async {
        guard policy.participatesInRepeatDetection,
              abnormalAccessMonitor.recordAccess(at: now()),
              settingsRepository.isClipboardAbnormalAccessAlertEnabled() else { return }

        do {
            try await notificationService.notify(
                .abnormalAccess(kind: .repeatedCopy, threshold: abnormalAccessThreshold)
            )
        } catch {
            Log.warn("비정상 접근 알림 발송 실패: \(error)", category: .notification)
        }
    }
}
