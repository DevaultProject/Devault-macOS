// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import Testing

@testable import DVPresentation

@MainActor
@Suite("GeneralSettingsFeature")
struct GeneralSettingsFeatureTests {
  @Test("기본 환경의 초기값은 Development다")
  func defaultEnvironmentInitiallyUsesDevelopment() {
    #expect(GeneralSettingsFeature.State().defaultEnvironment == .dev)
  }

  @Test("task는 현재 설정값을 읽어온다")
  func taskLoadsCurrentSettings() async {
    let store = TestStore(initialState: GeneralSettingsFeature.State()) {
      GeneralSettingsFeature()
    } withDependencies: {
      $0.generalSettingsClient.isLaunchAtLoginEnabled = { true }
      $0.generalSettingsClient.defaultEnvironment = { "prod" }
    }

    await store.send(.task) {
      $0.isLaunchAtLoginEnabled = true
      $0.defaultEnvironment = .prod
    }
  }

  @Test("저장된 환경값이 잘못되면 Development를 사용한다")
  func invalidDefaultEnvironmentFallsBackToDevelopment() async {
    var initialState = GeneralSettingsFeature.State()
    initialState.defaultEnvironment = .prod
    let store = TestStore(initialState: initialState) {
      GeneralSettingsFeature()
    } withDependencies: {
      $0.generalSettingsClient.isLaunchAtLoginEnabled = { false }
      $0.generalSettingsClient.defaultEnvironment = { "invalid" }
    }

    await store.send(.task) {
      $0.defaultEnvironment = .dev
    }
  }

  @Test("로그인 시 자동 실행 등록이 실패하면 토글을 되돌린다")
  func launchAtLoginRevertsOnFailure() async {
    var initial = GeneralSettingsFeature.State()
    initial.isLaunchAtLoginEnabled = false

    let store = TestStore(initialState: initial) {
      GeneralSettingsFeature()
    } withDependencies: {
      $0.generalSettingsClient.setLaunchAtLoginEnabled = { _ in throw CancellationError() }
    }

    await store.send(.binding(.set(\.isLaunchAtLoginEnabled, true))) {
      $0.isLaunchAtLoginEnabled = true
    }
    await store.receive(.launchAtLoginFailed(previousValue: false)) {
      $0.isLaunchAtLoginEnabled = false
    }
  }

  @Test("기본 환경을 선택하면 저장한다")
  func defaultEnvironmentSelectionPersists() async {
    let saved = LockIsolated("")
    let store = TestStore(initialState: GeneralSettingsFeature.State()) {
      GeneralSettingsFeature()
    } withDependencies: {
      $0.generalSettingsClient.setDefaultEnvironment = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.defaultEnvironment, .staging))) {
      $0.defaultEnvironment = .staging
    }
    #expect(saved.value == "staging")
  }
}
