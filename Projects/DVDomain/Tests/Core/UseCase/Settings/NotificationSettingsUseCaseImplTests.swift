// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("NotificationSettingsUseCaseImpl")
struct NotificationSettingsUseCaseImplTests {

    @Test("만료 알림 사용 여부를 읽고 쓴다")
    func expiryAlertsEnabledRoundTrips() {
        let repository = FakeSettingsRepository()
        let sut = NotificationSettingsUseCaseImpl(repository: repository)

        #expect(sut.isExpiryAlertsEnabled() == true)
        sut.setExpiryAlertsEnabled(false)
        #expect(sut.isExpiryAlertsEnabled() == false)
    }

    @Test("만료 알림 타이밍(며칠 전)을 읽고 쓴다")
    func expiryAlertDaysBeforeRoundTrips() {
        let repository = FakeSettingsRepository()
        let sut = NotificationSettingsUseCaseImpl(repository: repository)

        #expect(sut.expiryAlertDaysBefore() == [30, 7, 1, 0])
        sut.setExpiryAlertDaysBefore([7, 1])
        #expect(sut.expiryAlertDaysBefore() == [7, 1])
    }

    @Test("반복 인증 실패/클립보드 비정상 접근 알림 설정을 읽고 쓴다")
    func abnormalAccessAlertsRoundTrip() {
        let repository = FakeSettingsRepository()
        let sut = NotificationSettingsUseCaseImpl(repository: repository)

        #expect(sut.isAuthFailureAlertEnabled() == true)
        sut.setAuthFailureAlertEnabled(false)
        #expect(sut.isAuthFailureAlertEnabled() == false)

        #expect(sut.isClipboardAbnormalAccessAlertEnabled() == true)
        sut.setClipboardAbnormalAccessAlertEnabled(false)
        #expect(sut.isClipboardAbnormalAccessAlertEnabled() == false)
    }
}
