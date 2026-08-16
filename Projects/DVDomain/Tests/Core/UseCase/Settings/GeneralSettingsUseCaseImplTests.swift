// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("GeneralSettingsUseCaseImpl")
struct GeneralSettingsUseCaseImplTests {

  @Test("로그인 항목의 실제 상태를 반환하고 저장값을 동기화한다")
  func launchAtLoginStatusSynchronizesRepository() {
    let repository = FakeSettingsRepository()
    repository.isLaunchAtLoginEnabledValue = false

    let service = FakeLaunchAtLoginService()
    service.isEnabledValue = true

    let sut = GeneralSettingsUseCaseImpl(
      repository: repository,
      launchAtLoginService: service
    )

    #expect(sut.isLaunchAtLoginEnabled())
    #expect(repository.isLaunchAtLoginEnabledValue)
  }

  @Test("로그인 항목 변경에 성공하면 저장값을 갱신한다")
  func launchAtLoginUpdateSynchronizesRepository() throws {
    let repository = FakeSettingsRepository()
    let service = FakeLaunchAtLoginService()
    let sut = GeneralSettingsUseCaseImpl(
      repository: repository,
      launchAtLoginService: service
    )

    try sut.setLaunchAtLoginEnabled(true)

    #expect(service.isEnabledValue)
    #expect(repository.isLaunchAtLoginEnabledValue)
  }

  @Test("로그인 항목 변경에 실패하면 저장값을 변경하지 않는다")
  func launchAtLoginUpdateFailurePreservesRepository() {
    let repository = FakeSettingsRepository()
    let service = FakeLaunchAtLoginService()
    service.setEnabledError = .failed

    let sut = GeneralSettingsUseCaseImpl(
      repository: repository,
      launchAtLoginService: service
    )

    #expect(throws: FakeLaunchAtLoginService.Failure.failed) {
      try sut.setLaunchAtLoginEnabled(true)
    }
    #expect(!repository.isLaunchAtLoginEnabledValue)
  }

  @Test("기본 환경 설정을 읽고 쓴다")
  func defaultEnvironmentRoundTrips() {
    let repository = FakeSettingsRepository()
    let service = FakeLaunchAtLoginService()
    let sut = GeneralSettingsUseCaseImpl(
      repository: repository,
      launchAtLoginService: service
    )

    #expect(sut.defaultEnvironment() == "dev")
    sut.setDefaultEnvironment("prod")
    #expect(sut.defaultEnvironment() == "prod")
  }
}
