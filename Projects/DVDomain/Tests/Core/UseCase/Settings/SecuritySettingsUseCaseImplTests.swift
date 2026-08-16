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

    @Test("자동 잠금 설정을 읽고 쓴다")
    func autoLockSettingsRoundTrip() {
        let repository = FakeSettingsRepository()
        let sut = SecuritySettingsUseCaseImpl(repository: repository)

        #expect(sut.isAutoLockEnabled() == true)
        #expect(sut.autoLockMinutes() == 5)

        sut.setAutoLockEnabled(false)
        sut.setAutoLockMinutes(15)

        #expect(sut.isAutoLockEnabled() == false)
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
    func windowCaptureProtectionRoundTrips() {
        let repository = FakeSettingsRepository()
        let sut = SecuritySettingsUseCaseImpl(repository: repository)

        #expect(sut.isWindowCaptureProtectionEnabled() == true)
        sut.setWindowCaptureProtectionEnabled(false)
        #expect(sut.isWindowCaptureProtectionEnabled() == false)
    }

    @Test("화면 녹화 중 값 숨김 설정 스트림을 전달한다")
    func windowCaptureProtectionStreamPassesThrough() async {
        let repository = FakeSettingsRepository()
        repository.windowCaptureProtectionEnabledStreamValue = AsyncStream { continuation in
            continuation.yield(false)
            continuation.finish()
        }
        let sut = SecuritySettingsUseCaseImpl(repository: repository)

        var iterator = sut.windowCaptureProtectionEnabledStream().makeAsyncIterator()
        let value = await iterator.next()

        #expect(value == false)
    }
}
