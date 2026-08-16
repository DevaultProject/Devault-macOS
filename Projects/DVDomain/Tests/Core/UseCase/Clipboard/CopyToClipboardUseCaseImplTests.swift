// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("CopyToClipboardUseCaseImpl")
struct CopyToClipboardUseCaseImplTests {
    private let fixedInstant = ContinuousClock.now

    @Test("복사 인증 설정이 켜져 있으면 인증 후 값을 쓴다")
    func executeAuthenticatesWhenRequired() async throws {
        let clipboardService = FakeClipboardService()
        let authenticateUseCase = StubAuthenticateUseCase()
        let sut = makeSUT(
            clipboardService: clipboardService,
            authenticateUseCase: authenticateUseCase,
            settingsRepository: makeSettingsRepository(isRequireAuthToCopyEnabled: true)
        )

        try await sut.execute("secret-value")

        #expect(authenticateUseCase.authenticateCount == 1)
        #expect(authenticateUseCase.lastReason == AuthenticationReason.copySecret)
        #expect(clipboardService.writtenValues == ["secret-value"])
    }

    @Test("복사 인증 설정이 꺼져 있으면 인증 없이 값을 쓴다")
    func executeSkipsAuthenticationWhenDisabled() async throws {
        let clipboardService = FakeClipboardService()
        let authenticateUseCase = StubAuthenticateUseCase()
        let sut = makeSUT(
            clipboardService: clipboardService,
            authenticateUseCase: authenticateUseCase,
            settingsRepository: makeSettingsRepository(isRequireAuthToCopyEnabled: false)
        )

        try await sut.execute("secret-value")

        #expect(authenticateUseCase.authenticateCount == 0)
        #expect(clipboardService.writtenValues == ["secret-value"])
    }

    @Test("복사 인증에 실패하면 클립보드에 값을 쓰지 않는다")
    func executeDoesNotWriteWhenAuthenticationFails() async {
        let clipboardService = FakeClipboardService()
        let authenticateUseCase = StubAuthenticateUseCase()
        authenticateUseCase.error = .cancelled
        let sut = makeSUT(
            clipboardService: clipboardService,
            authenticateUseCase: authenticateUseCase,
            settingsRepository: makeSettingsRepository(isRequireAuthToCopyEnabled: true)
        )

        await #expect(throws: UserAuthenticationError.cancelled) {
            try await sut.execute("secret-value")
        }
        #expect(clipboardService.writtenValues.isEmpty)
    }

    @Test("값을 ClipboardService에 그대로 쓴다")
    func executeWritesValue() async throws {
        let clipboardService = FakeClipboardService()
        let sut = makeSUT(
            clipboardService: clipboardService,
            settingsRepository: makeSettingsRepository()
        )

        try await sut.execute("secret-value")

        #expect(clipboardService.writtenValues == ["secret-value"])
    }

    @Test("write가 실패하면 그대로 throw한다")
    func executeThrowsOnWriteFailure() async {
        let clipboardService = FakeClipboardService()
        clipboardService.errorOnWrite = .writeFailed
        let sut = makeSUT(
            clipboardService: clipboardService,
            settingsRepository: makeSettingsRepository()
        )

        await #expect(throws: ClipboardError.writeFailed) {
            try await sut.execute("secret-value")
        }
    }

    @Test("짧은 시간 안에 threshold회 복사하면 abnormalAccess 알림을 1회 보낸다")
    func executeNotifiesAbnormalAccessAtThreshold() async throws {
        let notificationService = FakeSecurityNotificationService()
        let sut = makeSUT(
            notificationService: notificationService,
            settingsRepository: makeSettingsRepository()
        )

        for _ in 0..<5 {
            try await sut.execute("secret-value")
        }

        #expect(notificationService.abnormalAccessCount == 1)
    }

    @Test("비정상 접근 알림이 꺼져 있으면 threshold에 도달해도 알림을 보내지 않는다")
    func disabledAbnormalAccessAlertDoesNotNotify() async throws {
        let notificationService = FakeSecurityNotificationService()
        let sut = makeSUT(
            notificationService: notificationService,
            settingsRepository: makeSettingsRepository(
                isClipboardAbnormalAccessAlertEnabled: false
            )
        )

        for _ in 0..<5 {
            try await sut.execute("secret-value")
        }

        #expect(notificationService.abnormalAccessCount == 0)
    }

    @Test("반복 감지 임계값은 조립 시점에 주입한 값을 따른다")
    func repeatDetectionThresholdIsInjected() async throws {
        let notificationService = FakeSecurityNotificationService()
        let sut = makeSUT(
            notificationService: notificationService,
            settingsRepository: makeSettingsRepository(),
            abnormalAccessThreshold: 2
        )

        try await sut.execute("secret-value")
        try await sut.execute("secret-value")

        #expect(notificationService.abnormalAccessCount == 1)
    }

    @Test("설정된 시간 뒤 pasteboard가 그대로면 정리하고 clipboardExceeded 알림을 보낸다")
    func executeClearsAndNotifiesWhenUnchanged() async throws {
        let clipboardService = FakeClipboardService()
        let notificationService = FakeSecurityNotificationService()
        let sut = makeSUT(
            clipboardService: clipboardService,
            notificationService: notificationService,
            settingsRepository: makeSettingsRepository(
                isAutoClearClipboardEnabled: true,
                autoClearClipboardDelaySeconds: 15
            )
        )

        try await sut.execute("secret-value")
        try await Task.sleep(for: .milliseconds(100))

        #expect(clipboardService.clearIfUnchangedCalls == [clipboardService.changeCountToReturn])
        #expect(notificationService.notified.contains(.clipboardExceeded(seconds: 15)))
    }

    @Test("클립보드 자동 비우기가 꺼져 있으면 정리를 예약하지 않는다")
    func executeSkipsAutoClearWhenDisabled() async throws {
        let clipboardService = FakeClipboardService()
        let sut = makeSUT(
            clipboardService: clipboardService,
            settingsRepository: makeSettingsRepository(isAutoClearClipboardEnabled: false)
        )

        try await sut.execute("secret-value")
        try await Task.sleep(for: .milliseconds(100))

        #expect(clipboardService.clearIfUnchangedCalls.isEmpty)
    }

    @Test("그 사이 다른 값이 복사됐으면 정리와 알림을 모두 건너뛴다")
    func executeSkipsWhenPasteboardChanged() async throws {
        let clipboardService = FakeClipboardService()
        clipboardService.clearIfUnchangedResult = false
        let notificationService = FakeSecurityNotificationService()
        let sut = makeSUT(
            clipboardService: clipboardService,
            notificationService: notificationService,
            settingsRepository: makeSettingsRepository(
                isAutoClearClipboardEnabled: true,
                autoClearClipboardDelaySeconds: 15
            )
        )

        try await sut.execute("secret-value")
        try await Task.sleep(for: .milliseconds(100))

        #expect(!notificationService.notified.contains(.clipboardExceeded(seconds: 15)))
    }

    // MARK: - Policy

    @Test("평문 정책은 값을 쓰되 인증은 요구하지 않는다")
    func plainPolicySkipsAuthentication() async throws {
        let clipboardService = FakeClipboardService()
        let authenticateUseCase = StubAuthenticateUseCase()
        let sut = makeSUT(
            clipboardService: clipboardService,
            authenticateUseCase: authenticateUseCase,
            settingsRepository: makeSettingsRepository(isRequireAuthToCopyEnabled: true)
        )

        try await sut.execute("redirect-url", policy: .plain)

        #expect(authenticateUseCase.authenticateCount == 0)
        #expect(clipboardService.writtenValues == ["redirect-url"])
    }

    @Test("평문 정책은 자동 비우기가 켜져 있어도 정리를 예약하지 않는다")
    func plainPolicySkipsAutoClear() async throws {
        let clipboardService = FakeClipboardService()
        let sut = makeSUT(
            clipboardService: clipboardService,
            settingsRepository: makeSettingsRepository(
                isAutoClearClipboardEnabled: true,
                autoClearClipboardDelaySeconds: 15
            )
        )

        try await sut.execute("redirect-url", policy: .plain)
        try await Task.sleep(for: .milliseconds(100))

        #expect(clipboardService.clearIfUnchangedCalls.isEmpty)
    }

    /// 알림만 막는 것으로는 부족하다 — 평문 복사가 카운터에 쌓이면 이어지는 민감 값 복사 한 번이
    /// 임계값을 넘겨 오탐이 난다.
    @Test("평문 정책 복사는 반복 감지 카운터에 쌓이지 않는다")
    func plainPolicyDoesNotFeedRepeatDetection() async throws {
        let notificationService = FakeSecurityNotificationService()
        let sut = makeSUT(
            notificationService: notificationService,
            settingsRepository: makeSettingsRepository()
        )

        for _ in 0..<4 {
            try await sut.execute("redirect-url", policy: .plain)
        }
        try await sut.execute("secret-value", policy: .sensitive)

        #expect(notificationService.abnormalAccessCount == 0)
    }

    /// 세 축이 각각 독립으로 걸리는지 본다 — 프리셋 두 개만 검증하면 구현이 `policy == .sensitive`로
    /// 뭉뚱그려져 있어도 통과한다.
    @Test("자동 정리에만 참여하는 정책은 정리만 하고 인증·반복 감지는 건너뛴다")
    func policyAxesApplyIndependently() async throws {
        let clipboardService = FakeClipboardService()
        let authenticateUseCase = StubAuthenticateUseCase()
        let notificationService = FakeSecurityNotificationService()
        let sut = makeSUT(
            clipboardService: clipboardService,
            notificationService: notificationService,
            authenticateUseCase: authenticateUseCase,
            settingsRepository: makeSettingsRepository(
                isRequireAuthToCopyEnabled: true,
                isAutoClearClipboardEnabled: true,
                autoClearClipboardDelaySeconds: 15
            ),
            abnormalAccessThreshold: 2
        )
        let autoClearOnly = ClipboardCopyPolicy(
            requiresAuthentication: false,
            participatesInAutoClear: true,
            participatesInRepeatDetection: false
        )

        try await sut.execute("value", policy: autoClearOnly)
        try await sut.execute("value", policy: autoClearOnly)
        try await Task.sleep(for: .milliseconds(100))

        #expect(authenticateUseCase.authenticateCount == 0)
        #expect(clipboardService.clearIfUnchangedCalls.count == 2)
        #expect(notificationService.abnormalAccessCount == 0)
    }

    @Test("정책을 생략하면 민감 값 정책이 적용된다")
    func sensitiveIsTheDefaultPolicy() async throws {
        let clipboardService = FakeClipboardService()
        let authenticateUseCase = StubAuthenticateUseCase()
        let notificationService = FakeSecurityNotificationService()
        let sut = makeSUT(
            clipboardService: clipboardService,
            notificationService: notificationService,
            authenticateUseCase: authenticateUseCase,
            settingsRepository: makeSettingsRepository(
                isRequireAuthToCopyEnabled: true,
                isAutoClearClipboardEnabled: true,
                autoClearClipboardDelaySeconds: 15
            )
        )

        for _ in 0..<5 {
            try await sut.execute("secret-value")
        }
        try await Task.sleep(for: .milliseconds(100))

        #expect(authenticateUseCase.authenticateCount == 5)
        #expect(!clipboardService.clearIfUnchangedCalls.isEmpty)
        #expect(notificationService.abnormalAccessCount == 1)
    }
}

extension CopyToClipboardUseCaseImplTests {

    /// `sleep`은 모든 테스트에서 즉시 반환한다 — 자동 정리 예약 여부만 보면 되고 실제 지연은 볼 것이 없다.
    private func makeSUT(
        clipboardService: FakeClipboardService = FakeClipboardService(),
        notificationService: FakeSecurityNotificationService = FakeSecurityNotificationService(),
        authenticateUseCase: StubAuthenticateUseCase = StubAuthenticateUseCase(),
        settingsRepository: FakeSettingsRepository,
        abnormalAccessThreshold: Int = 5
    ) -> CopyToClipboardUseCaseImpl {
        CopyToClipboardUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            authenticateUseCase: authenticateUseCase,
            settingsRepository: settingsRepository,
            abnormalAccessWindow: .seconds(60),
            abnormalAccessThreshold: abnormalAccessThreshold,
            now: { self.fixedInstant },
            sleep: { _ in }
        )
    }

    private func makeSettingsRepository(
        isRequireAuthToCopyEnabled: Bool = false,
        isAutoClearClipboardEnabled: Bool = false,
        autoClearClipboardDelaySeconds: Int = 30,
        isClipboardAbnormalAccessAlertEnabled: Bool = true
    ) -> FakeSettingsRepository {
        let repository = FakeSettingsRepository()
        repository.isRequireAuthToCopyEnabledValue = isRequireAuthToCopyEnabled
        repository.isAutoClearClipboardEnabledValue = isAutoClearClipboardEnabled
        repository.autoClearClipboardDelaySecondsValue = autoClearClipboardDelaySeconds
        repository.isClipboardAbnormalAccessAlertEnabledValue = isClipboardAbnormalAccessAlertEnabled
        return repository
    }
}

private extension FakeSecurityNotificationService {
    var abnormalAccessCount: Int {
        notified.filter {
            if case .abnormalAccess = $0 { return true }
            return false
        }.count
    }
}

private final class StubAuthenticateUseCase: AuthenticateUseCase, @unchecked Sendable {
    var error: UserAuthenticationError?
    private(set) var authenticateCount = 0
    private(set) var lastReason: String?

    func authenticate(reason: String) async throws {
        authenticateCount += 1
        lastReason = reason
        if let error { throw error }
    }
}
