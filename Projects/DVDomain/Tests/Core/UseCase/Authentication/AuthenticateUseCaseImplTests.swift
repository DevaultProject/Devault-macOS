// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("AuthenticateUseCaseImpl")
struct AuthenticateUseCaseImplTests {
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("인증 실패는 그대로 던진다")
    func authenticateRethrowsFailure() async {
        let authenticationService = StubUserAuthenticationService()
        authenticationService.errorOnAuthenticate = .failed
        let sut = AuthenticateUseCaseImpl(
            authenticationService: authenticationService,
            notificationService: FakeSecurityNotificationService(),
            now: { self.fixedDate }
        )

        await #expect(throws: UserAuthenticationError.failed) {
            try await sut.authenticate(reason: "test")
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
            now: { self.fixedDate }
        )

        for _ in 0..<2 {
            _ = try? await sut.authenticate(reason: "test")
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
            now: { self.fixedDate }
        )

        for _ in 0..<3 {
            _ = try? await sut.authenticate(reason: "test")
        }

        #expect(notificationService.notified.count == 1)
        #expect(notificationService.notified.first == .abnormalAccess(
            reason: "짧은 시간 안에 인증 실패가 3회 이상 반복됨"
        ))
    }

    @Test("인증 성공은 반복 실패 카운트에 반영되지 않는다")
    func successDoesNotCountTowardThreshold() async {
        let authenticationService = StubUserAuthenticationService()
        let notificationService = FakeSecurityNotificationService()
        let sut = AuthenticateUseCaseImpl(
            authenticationService: authenticationService,
            notificationService: notificationService,
            now: { self.fixedDate }
        )

        for _ in 0..<10 {
            try? await sut.authenticate(reason: "test")
        }

        #expect(notificationService.notified.isEmpty)
    }
}
