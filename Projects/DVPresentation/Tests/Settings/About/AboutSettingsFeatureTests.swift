// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Testing

@testable import DVPresentation

@MainActor
@Suite("AboutSettingsFeature")
struct AboutSettingsFeatureTests {

  @Test("task는 앱 버전을 읽어온다")
  func taskLoadsAppVersion() async {
    let store = TestStore(initialState: AboutSettingsFeature.State()) {
      AboutSettingsFeature()
    } withDependencies: {
      $0.aboutSettingsClient.appVersion = { "2.0.0" }
    }

    await store.send(.task) {
      $0.version = "2.0.0"
    }
  }

  @Test("didTapOpenSourceLicenses는 라이선스 sheet를 연다")
  func didTapOpenSourceLicensesOpensSheet() async {
    let store = TestStore(initialState: AboutSettingsFeature.State()) {
      AboutSettingsFeature()
    }

    await store.send(.didTapOpenSourceLicenses) {
      $0.isShowingLicenses = true
    }
  }
}
