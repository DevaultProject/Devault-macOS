// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("NotificationSettingsUseCaseImpl")
struct NotificationSettingsUseCaseImplTests {

    @Test("만료 알림 사용 여부를 읽고 쓴다")
    func expiryAlertsEnabledRoundTrips() async throws {
        let repository = FakeSettingsRepository()
        let scheduler = StubExpiryNotificationScheduler()
        let sut = NotificationSettingsUseCaseImpl(
            repository: repository,
            expiryNotificationScheduler: scheduler
        )

        #expect(sut.isExpiryAlertsEnabled() == true)
        try await sut.setExpiryAlertsEnabled(false)
        #expect(sut.isExpiryAlertsEnabled() == false)
        #expect(scheduler.syncAllCount == 1)
    }

    @Test("만료 알림 타이밍(며칠 전)을 읽고 쓴다")
    func expiryAlertDaysBeforeRoundTrips() async throws {
        let repository = FakeSettingsRepository()
        let scheduler = StubExpiryNotificationScheduler()
        let sut = NotificationSettingsUseCaseImpl(
            repository: repository,
            expiryNotificationScheduler: scheduler
        )

        #expect(sut.expiryAlertDaysBefore() == ExpiryAlertDay.defaultSelection)
        try await sut.setExpiryAlertDaysBefore([.sevenDaysBefore, .threeDaysBefore])
        #expect(sut.expiryAlertDaysBefore() == [.sevenDaysBefore, .threeDaysBefore])
        #expect(scheduler.syncAllCount == 1)
    }

    @Test("반복 인증 실패/클립보드 비정상 접근 알림 설정을 읽고 쓴다")
    func abnormalAccessAlertsRoundTrip() {
        let repository = FakeSettingsRepository()
        let sut = NotificationSettingsUseCaseImpl(
            repository: repository,
            expiryNotificationScheduler: StubExpiryNotificationScheduler()
        )

        #expect(sut.isAuthFailureAlertEnabled() == true)
        sut.setAuthFailureAlertEnabled(false)
        #expect(sut.isAuthFailureAlertEnabled() == false)

        #expect(sut.isClipboardAbnormalAccessAlertEnabled() == true)
        sut.setClipboardAbnormalAccessAlertEnabled(false)
        #expect(sut.isClipboardAbnormalAccessAlertEnabled() == false)
    }
}

private final class StubExpiryNotificationScheduler: ScheduleSecretExpiryNotificationsUseCase, @unchecked Sendable {
    private(set) var syncAllCount = 0

    func syncAll() async throws {
        syncAllCount += 1
    }

    func schedule(secret: Secret) async {}
    func cancel(secretID: UUID) async {}
}
