// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("SecuritySettingsUseCaseImpl")
struct SecuritySettingsUseCaseImplTests {

    @Test("인증 관련 토글을 읽고 쓴다")
    func authTogglesRoundTrip() {
        let repository = FakeSettingsRepository()
        let sut = SecuritySettingsUseCaseImpl(repository: repository)

        #expect(sut.isRequireAuthOnLaunchEnabled() == true)
        sut.setRequireAuthOnLaunchEnabled(false)
        #expect(sut.isRequireAuthOnLaunchEnabled() == false)

        #expect(sut.isRequireAuthToCopyEnabled() == true)
        sut.setRequireAuthToCopyEnabled(false)
        #expect(sut.isRequireAuthToCopyEnabled() == false)
    }

    @Test("자동 잠금 시간을 읽고 쓴다")
    func autoLockMinutesRoundTrips() {
        let repository = FakeSettingsRepository()
        let sut = SecuritySettingsUseCaseImpl(repository: repository)

        #expect(sut.autoLockMinutes() == 5)
        sut.setAutoLockMinutes(15)
        #expect(sut.autoLockMinutes() == 15)
    }

    @Test("클립보드 자동 비우기 설정을 읽고 쓴다")
    func clipboardSettingsRoundTrip() {
        let repository = FakeSettingsRepository()
        let sut = SecuritySettingsUseCaseImpl(repository: repository)

        #expect(sut.isAutoClearClipboardEnabled() == true)
        #expect(sut.autoClearClipboardDelaySeconds() == 30)

        sut.setAutoClearClipboardEnabled(false)
        sut.setAutoClearClipboardDelaySeconds(60)

        #expect(sut.isAutoClearClipboardEnabled() == false)
        #expect(sut.autoClearClipboardDelaySeconds() == 60)
    }

    @Test("화면 녹화 중 값 숨김 설정을 읽고 쓴다")
    func hideDuringScreenRecordingRoundTrips() {
        let repository = FakeSettingsRepository()
        let sut = SecuritySettingsUseCaseImpl(repository: repository)

        #expect(sut.isHideDuringScreenRecordingEnabled() == true)
        sut.setHideDuringScreenRecordingEnabled(false)
        #expect(sut.isHideDuringScreenRecordingEnabled() == false)
    }
}
