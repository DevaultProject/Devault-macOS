// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("AuthenticateUseCaseImpl")
struct AuthenticateUseCaseImplTests {
    private let fixedInstant = ContinuousClock.now

    @Test("인증 실패는 그대로 던진다")
    func authenticateRethrowsFailure() async {
        let authenticationService = StubUserAuthenticationService()
        authenticationService.errorOnAuthenticate = .failed
        let sut = AuthenticateUseCaseImpl(
            authenticationService: authenticationService,
            notificationService: FakeSecurityNotificationService(),
            settingsRepository: FakeSettingsRepository(),
            now: { self.fixedInstant }
        )

        await #expect(throws: UserAuthenticationError.failed) {
            try await sut.authenticate(reason: .revealSecret)
        }
    }

    @Test("threshold 미만 실패는 알림을 보내지 않는다")
    func belowThresholdDoesNotNotify() async {
        let authenticationService = StubUserAuthenticationService()
        authenticationService.errorOnAuthenticate = .failed
        let notificationService = FakeSecurityNotificationService()
        let sut = AuthenticateUseCaseImpl(
            authenticationService: authenticationService,
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            now: { self.fixedInstant }
        )

        for _ in 0..<2 {
            _ = try? await sut.authenticate(reason: .revealSecret)
        }

        #expect(notificationService.notified.isEmpty)
    }

    @Test("짧은 시간 안에 threshold회 실패하면 abnormalAccess 알림을 1회 보낸다")
    func thresholdReachedNotifiesOnce() async {
        let authenticationService = StubUserAuthenticationService()
        authenticationService.errorOnAuthenticate = .failed
        let notificationService = FakeSecurityNotificationService()
        let sut = AuthenticateUseCaseImpl(
            authenticationService: authenticationService,
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            postNotificationDelay: .milliseconds(0),
            now: { self.fixedInstant }
        )

        for _ in 0..<3 {
            _ = try? await sut.authenticate(reason: .revealSecret)
        }

        #expect(notificationService.notified.count == 1)
        #expect(notificationService.notified.first == .abnormalAccess(
            kind: .authenticationFailure, threshold: 3
        ))
    }

    @Test("비정상 접근 알림이 꺼져 있으면 threshold에 도달해도 알림을 보내지 않는다")
    func disabledAlertDoesNotNotifyEvenAtThreshold() async {
        let authenticationService = StubUserAuthenticationService()
        authenticationService.errorOnAuthenticate = .failed
        let notificationService = FakeSecurityNotificationService()
        let settingsRepository = FakeSettingsRepository()
        settingsRepository.isAuthFailureAlertEnabledValue = false
        let sut = AuthenticateUseCaseImpl(
            authenticationService: authenticationService,
            notificationService: notificationService,
            settingsRepository: settingsRepository,
            postNotificationDelay: .milliseconds(0),
            now: { self.fixedInstant }
        )

        for _ in 0..<3 {
            _ = try? await sut.authenticate(reason: .revealSecret)
        }

        #expect(notificationService.notified.isEmpty)
    }

    @Test("인증 성공은 반복 실패 카운트에 반영되지 않는다")
    func successDoesNotCountTowardThreshold() async {
        let authenticationService = StubUserAuthenticationService()
        let notificationService = FakeSecurityNotificationService()
        let sut = AuthenticateUseCaseImpl(
            authenticationService: authenticationService,
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            now: { self.fixedInstant }
        )

        for _ in 0..<10 {
            try? await sut.authenticate(reason: .revealSecret)
        }

        #expect(notificationService.notified.isEmpty)
    }
}
