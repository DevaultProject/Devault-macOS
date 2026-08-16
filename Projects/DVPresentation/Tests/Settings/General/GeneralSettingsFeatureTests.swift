// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain
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
      $0.generalSettingsClient.launchAtLoginStatus = { .enabled }
      $0.generalSettingsClient.defaultEnvironment = { "prod" }
    }

    await store.send(.task) {
      $0.isLaunchAtLoginEnabled = true
      $0.launchAtLoginStatus = .enabled
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
      $0.generalSettingsClient.launchAtLoginStatus = { .notRegistered }
      $0.generalSettingsClient.defaultEnvironment = { "invalid" }
    }

    await store.send(.task) {
      $0.defaultEnvironment = .dev
    }
  }

  @Test("승인 대기 상태에서는 토글을 유지하고 승인 상태를 표시한다")
  func launchAtLoginKeepsToggleOnWhenApprovalIsRequired() async {
    let store = TestStore(initialState: GeneralSettingsFeature.State()) {
      GeneralSettingsFeature()
    } withDependencies: {
      $0.generalSettingsClient.setLaunchAtLoginEnabled = { _ in .requiresApproval }
    }

    await store.send(.binding(.set(\.isLaunchAtLoginEnabled, true))) {
      $0.isLaunchAtLoginEnabled = true
    }
    await store.receive(.launchAtLoginStatusChanged(.requiresApproval)) {
      $0.launchAtLoginStatus = .requiresApproval
    }
  }

  @Test("로그인 항목 시스템 설정 열기를 요청한다")
  func openLoginItemsSettingsCallsClient() async {
    let opened = LockIsolated(false)
    let store = TestStore(initialState: GeneralSettingsFeature.State()) {
      GeneralSettingsFeature()
    } withDependencies: {
      $0.generalSettingsClient.openLoginItemsSystemSettings = { opened.setValue(true) }
    }

    await store.send(.didTapOpenLoginItemsSettings)

    #expect(opened.value)
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
