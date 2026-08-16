// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("CopySensitiveValueUseCaseImpl")
struct CopySensitiveValueUseCaseImplTests {
    private let fixedInstant = ContinuousClock.now

    @Test("복사 인증 설정이 켜져 있으면 인증 후 값을 쓴다")
    func executeAuthenticatesWhenRequired() async throws {
        let clipboardService = FakeClipboardService()
        let authenticateUseCase = StubAuthenticateUseCase()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: FakeSecurityNotificationService(),
            authenticateUseCase: authenticateUseCase,
            settingsRepository: makeSettingsRepository(isRequireAuthToCopyEnabled: true),
            now: { self.fixedInstant }
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
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: FakeSecurityNotificationService(),
            authenticateUseCase: authenticateUseCase,
            settingsRepository: makeSettingsRepository(isRequireAuthToCopyEnabled: false),
            now: { self.fixedInstant }
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
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: FakeSecurityNotificationService(),
            authenticateUseCase: authenticateUseCase,
            settingsRepository: makeSettingsRepository(isRequireAuthToCopyEnabled: true),
            now: { self.fixedInstant }
        )

        await #expect(throws: UserAuthenticationError.cancelled) {
            try await sut.execute("secret-value")
        }
        #expect(clipboardService.writtenValues.isEmpty)
    }

    @Test("값을 ClipboardService에 그대로 쓴다")
    func executeWritesValue() async throws {
        let clipboardService = FakeClipboardService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: FakeSecurityNotificationService(),
            authenticateUseCase: StubAuthenticateUseCase(),
            settingsRepository: makeSettingsRepository(),
            now: { self.fixedInstant }
        )

        try await sut.execute("secret-value")

        #expect(clipboardService.writtenValues == ["secret-value"])
    }

    @Test("write가 실패하면 그대로 throw한다")
    func executeThrowsOnWriteFailure() async {
        let clipboardService = FakeClipboardService()
        clipboardService.errorOnWrite = .writeFailed
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: FakeSecurityNotificationService(),
            authenticateUseCase: StubAuthenticateUseCase(),
            settingsRepository: makeSettingsRepository(),
            now: { self.fixedInstant }
        )

        await #expect(throws: ClipboardError.writeFailed) {
            try await sut.execute("secret-value")
        }
    }

    @Test("짧은 시간 안에 threshold회 복사하면 abnormalAccess 알림을 1회 보낸다")
    func executeNotifiesAbnormalAccessAtThreshold() async throws {
        let clipboardService = FakeClipboardService()
        let notificationService = FakeSecurityNotificationService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            authenticateUseCase: StubAuthenticateUseCase(),
            settingsRepository: makeSettingsRepository(),
            now: { self.fixedInstant }
        )

        for _ in 0..<5 {
            try await sut.execute("secret-value")
        }

        let abnormalAccessCount = notificationService.notified.filter {
            if case .abnormalAccess = $0 { return true }
            return false
        }.count
        #expect(abnormalAccessCount == 1)
    }

    @Test("비정상 접근 알림이 꺼져 있으면 threshold에 도달해도 알림을 보내지 않는다")
    func disabledAbnormalAccessAlertDoesNotNotify() async throws {
        let clipboardService = FakeClipboardService()
        let notificationService = FakeSecurityNotificationService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            authenticateUseCase: StubAuthenticateUseCase(),
            settingsRepository: makeSettingsRepository(
                isClipboardAbnormalAccessAlertEnabled: false
            ),
            now: { self.fixedInstant }
        )

        for _ in 0..<5 {
            try await sut.execute("secret-value")
        }

        let abnormalAccessCount = notificationService.notified.filter {
            if case .abnormalAccess = $0 { return true }
            return false
        }.count
        #expect(abnormalAccessCount == 0)
    }

    @Test("설정된 시간 뒤 pasteboard가 그대로면 정리하고 clipboardExceeded 알림을 보낸다")
    func executeClearsAndNotifiesWhenUnchanged() async throws {
        let clipboardService = FakeClipboardService()
        let notificationService = FakeSecurityNotificationService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            authenticateUseCase: StubAuthenticateUseCase(),
            settingsRepository: makeSettingsRepository(
                isAutoClearClipboardEnabled: true,
                autoClearClipboardDelaySeconds: 15
            ),
            now: { self.fixedInstant },
            sleep: { _ in }
        )

        try await sut.execute("secret-value")
        try await Task.sleep(for: .milliseconds(100))

        #expect(clipboardService.clearIfUnchangedCalls == [clipboardService.changeCountToReturn])
        #expect(notificationService.notified.contains(.clipboardExceeded(seconds: 15)))
    }

    @Test("클립보드 자동 비우기가 꺼져 있으면 정리를 예약하지 않는다")
    func executeSkipsAutoClearWhenDisabled() async throws {
        let clipboardService = FakeClipboardService()
        let notificationService = FakeSecurityNotificationService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            authenticateUseCase: StubAuthenticateUseCase(),
            settingsRepository: makeSettingsRepository(
                isAutoClearClipboardEnabled: false
            ),
            now: { self.fixedInstant },
            sleep: { _ in }
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
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            authenticateUseCase: StubAuthenticateUseCase(),
            settingsRepository: makeSettingsRepository(
                isAutoClearClipboardEnabled: true,
                autoClearClipboardDelaySeconds: 15
            ),
            now: { self.fixedInstant },
            sleep: { _ in }
        )

        try await sut.execute("secret-value")
        try await Task.sleep(for: .milliseconds(100))

        #expect(!notificationService.notified.contains(.clipboardExceeded(seconds: 15)))
    }
}

extension CopySensitiveValueUseCaseImplTests {
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
