// Copyright © 2026 Devault. All rights reserved

import Testing

@testable import DVDomain

@Suite("MonitorAppInactivityUseCaseImpl")
struct MonitorAppInactivityUseCaseImplTests {

  @Test("앱 비활성 시간이 설정 시간을 넘으면 타임아웃을 방출한다")
  func emitsTimeoutAfterConfiguredInactivity() async {
    let service = FakeAppInactivityMonitorService()
    service.inactivitySecondsValues = [0, 299, 300]
    let repository = FakeSettingsRepository()
    repository.isAutoLockEnabledValue = true
    repository.autoLockMinutesValue = 5
    let sut = MonitorAppInactivityUseCaseImpl(
      service: service,
      repository: repository
    )

    var timeoutCount = 0
    for await _ in sut.timeoutStream() {
      timeoutCount += 1
    }

    #expect(timeoutCount == 1)
  }

  @Test("자동 잠금이 꺼져 있으면 타임아웃을 방출하지 않는다")
  func doesNotEmitTimeoutWhenDisabled() async {
    let service = FakeAppInactivityMonitorService()
    service.inactivitySecondsValues = [300]
    let repository = FakeSettingsRepository()
    repository.isAutoLockEnabledValue = false
    let sut = MonitorAppInactivityUseCaseImpl(
      service: service,
      repository: repository
    )

    var didTimeout = false
    for await _ in sut.timeoutStream() {
      didTimeout = true
    }

    #expect(!didTimeout)
  }

  @Test("앱 비활성 시간이 설정 시간보다 짧으면 타임아웃을 방출하지 않는다")
  func doesNotEmitTimeoutBeforeConfiguredInactivity() async {
    let service = FakeAppInactivityMonitorService()
    service.inactivitySecondsValues = [0, 299]
    let repository = FakeSettingsRepository()
    repository.isAutoLockEnabledValue = true
    repository.autoLockMinutesValue = 5
    let sut = MonitorAppInactivityUseCaseImpl(
      service: service,
      repository: repository
    )

    var didTimeout = false
    for await _ in sut.timeoutStream() {
      didTimeout = true
    }

    #expect(!didTimeout)
  }
}
