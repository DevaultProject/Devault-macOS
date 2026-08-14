// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("GeneralSettingsUseCaseImpl")
struct GeneralSettingsUseCaseImplTests {

    @Test("로그인 시 자동 실행 설정을 읽고 쓴다")
    func launchAtLoginRoundTrips() {
        let repository = FakeSettingsRepository()
        let sut = GeneralSettingsUseCaseImpl(repository: repository)

        #expect(sut.isLaunchAtLoginEnabled() == false)
        sut.setLaunchAtLoginEnabled(true)
        #expect(sut.isLaunchAtLoginEnabled() == true)
        #expect(repository.isLaunchAtLoginEnabledValue == true)
    }

    @Test("기본 환경 설정을 읽고 쓴다")
    func defaultEnvironmentRoundTrips() {
        let repository = FakeSettingsRepository()
        let sut = GeneralSettingsUseCaseImpl(repository: repository)

        #expect(sut.defaultEnvironment() == nil)
        sut.setDefaultEnvironment("prod")
        #expect(sut.defaultEnvironment() == "prod")
    }
}
