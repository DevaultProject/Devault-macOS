// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import Testing

@testable import DVPresentation

@MainActor
@Suite("SecuritySettingsFeature")
struct SecuritySettingsFeatureTests {
  @Test("task는 현재 설정값을 읽어온다")
  func taskLoadsCurrentSettings() async {
    let store = TestStore(initialState: SecuritySettingsFeature.State()) {
      SecuritySettingsFeature()
    } withDependencies: {
      $0.securitySettingsClient.isRequireAuthOnLaunchEnabled = { false }
      $0.securitySettingsClient.isRequireAuthToCopyEnabled = { false }
      $0.securitySettingsClient.isAutoLockEnabled = { false }
      $0.securitySettingsClient.autoLockMinutes = { 15 }
      $0.securitySettingsClient.isAutoClearClipboardEnabled = { false }
      $0.securitySettingsClient.autoClearClipboardDelaySeconds = { 60 }
      $0.securitySettingsClient.isHideDuringScreenRecordingEnabled = { false }
    }

    await store.send(.task) {
      $0.isRequireAuthOnLaunchEnabled = false
      $0.isRequireAuthToCopyEnabled = false
      $0.isAutoLockEnabled = false
      $0.autoLockInterval = .fifteenMinutes
      $0.isAutoClearClipboardEnabled = false
      $0.clipboardClearDelay = .oneMinute
      $0.isHideDuringScreenRecordingEnabled = false
    }
  }

  @Test("자동 잠금 시간을 선택하면 저장한다")
  func autoLockIntervalSelectionPersists() async {
    let saved = LockIsolated<Int?>(nil)
    let store = TestStore(initialState: SecuritySettingsFeature.State()) {
      SecuritySettingsFeature()
    } withDependencies: {
      $0.securitySettingsClient.setAutoLockMinutes = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.autoLockInterval, .fifteenMinutes))) {
      $0.autoLockInterval = .fifteenMinutes
    }
    #expect(saved.value == 15)
  }

  @Test("자동 잠금 토글을 저장한다")
  func autoLockTogglePersists() async {
    let saved = LockIsolated<Bool?>(nil)
    let store = TestStore(initialState: SecuritySettingsFeature.State()) {
      SecuritySettingsFeature()
    } withDependencies: {
      $0.securitySettingsClient.setAutoLockEnabled = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.isAutoLockEnabled, false))) {
      $0.isAutoLockEnabled = false
    }
    #expect(saved.value == false)
  }

  @Test("앱 실행 시 인증 요구 토글을 저장한다")
  func requireAuthOnLaunchTogglePersists() async {
    let saved = LockIsolated<Bool?>(nil)
    let store = TestStore(initialState: SecuritySettingsFeature.State()) {
      SecuritySettingsFeature()
    } withDependencies: {
      $0.securitySettingsClient.setRequireAuthOnLaunchEnabled = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.isRequireAuthOnLaunchEnabled, false))) {
      $0.isRequireAuthOnLaunchEnabled = false
    }
    #expect(saved.value == false)
  }

  @Test("복사 시 인증 요구 토글을 저장한다")
  func requireAuthToCopyTogglePersists() async {
    let saved = LockIsolated<Bool?>(nil)
    let store = TestStore(initialState: SecuritySettingsFeature.State()) {
      SecuritySettingsFeature()
    } withDependencies: {
      $0.securitySettingsClient.setRequireAuthToCopyEnabled = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.isRequireAuthToCopyEnabled, false))) {
      $0.isRequireAuthToCopyEnabled = false
    }
    #expect(saved.value == false)
  }

  @Test("클립보드 자동 비우기 토글을 저장한다")
  func autoClearClipboardTogglePersists() async {
    let saved = LockIsolated<Bool?>(nil)
    let store = TestStore(initialState: SecuritySettingsFeature.State()) {
      SecuritySettingsFeature()
    } withDependencies: {
      $0.securitySettingsClient.setAutoClearClipboardEnabled = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.isAutoClearClipboardEnabled, false))) {
      $0.isAutoClearClipboardEnabled = false
    }
    #expect(saved.value == false)
  }

  @Test("클립보드 자동 비우기 시간을 선택하면 저장한다")
  func autoClearClipboardDelaySelectionPersists() async {
    let saved = LockIsolated<Int?>(nil)
    let store = TestStore(initialState: SecuritySettingsFeature.State()) {
      SecuritySettingsFeature()
    } withDependencies: {
      $0.securitySettingsClient.setAutoClearClipboardDelaySeconds = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.clipboardClearDelay, .oneMinute))) {
      $0.clipboardClearDelay = .oneMinute
    }
    #expect(saved.value == 60)
  }

  @Test("화면 녹화 중 값 숨김 토글을 저장한다")
  func hideDuringScreenRecordingTogglePersists() async {
    let saved = LockIsolated<Bool?>(nil)
    let store = TestStore(initialState: SecuritySettingsFeature.State()) {
      SecuritySettingsFeature()
    } withDependencies: {
      $0.securitySettingsClient.setHideDuringScreenRecordingEnabled = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.isHideDuringScreenRecordingEnabled, false))) {
      $0.isHideDuringScreenRecordingEnabled = false
    }
    #expect(saved.value == false)
  }
}
