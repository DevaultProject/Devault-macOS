// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain
import Testing

@testable import DVPresentation

@MainActor
@Suite("ICloudSettingsFeature")
struct ICloudSettingsFeatureTests {
  @Test("task는 현재 설정값을 읽고 카운트를 조회한다")
  func taskLoadsCurrentSettings() async {
    let store = TestStore(initialState: ICloudSettingsFeature.State()) {
      ICloudSettingsFeature()
    } withDependencies: {
      $0.iCloudSettingsClient.isEnabled = { true }
      $0.iCloudSettingsClient.lastSyncedAt = { nil }
      $0.iCloudSettingsClient.syncedSecretCount = { 3 }
      $0.iCloudSettingsClient.syncedProjectCount = { 1 }
      $0.iCloudSettingsClient.remoteChangeStream = { AsyncStream { $0.finish() } }
    }

    await store.send(.task) {
      $0.isSyncEnabled = true
    }
    await store.receive(.countsResponse(secretCount: 3, projectCount: 1)) {
      $0.syncedSecretCount = 3
      $0.syncedProjectCount = 1
    }
  }

  @Test("동기화 켜기가 성공하면 저장소 구성을 적용한다")
  func enableSyncSucceeds() async {
    let store = TestStore(initialState: ICloudSettingsFeature.State()) {
      ICloudSettingsFeature()
    } withDependencies: {
      $0.iCloudSettingsClient.accountStatus = { .available }
      $0.iCloudSettingsClient.setEnabled = { _ in }
    }

    await store.send(.binding(.set(\.isSyncEnabled, true))) {
      $0.isSyncEnabled = true
      $0.isTogglingSync = true
    }
    await store.receive(.enableSyncStatusResponse(.available))
    await store.receive(.syncSettingResponse(enabled: true, succeeded: true)) {
      $0.isTogglingSync = false
      $0.isSyncEnabled = true
    }
  }

  @Test("동기화 켜기가 실패하면 alert를 띄운다")
  func enableSyncFailsShowsAlert() async {
    let store = TestStore(initialState: ICloudSettingsFeature.State()) {
      ICloudSettingsFeature()
    } withDependencies: {
      $0.iCloudSettingsClient.accountStatus = { .noAccount }
    }

    await store.send(.binding(.set(\.isSyncEnabled, true))) {
      $0.isSyncEnabled = true
      $0.isTogglingSync = true
    }
    await store.receive(.enableSyncStatusResponse(.noAccount)) {
      $0.isTogglingSync = false
      $0.isSyncEnabled = false
      $0.alert = makeICloudSyncUnavailableAlert(
        .noAccount,
        retry: .retry,
        continueWithoutSync: .continueWithoutSync,
        openSystemSettings: .openSystemSettings
      )
    }
  }

  @Test("동기화 끄기는 계정 확인 없이 저장소 구성을 적용한다")
  func disableSyncSkipsAccountCheck() async {
    let saved = LockIsolated<Bool?>(nil)
    var initial = ICloudSettingsFeature.State()
    initial.isSyncEnabled = true

    let store = TestStore(initialState: initial) {
      ICloudSettingsFeature()
    } withDependencies: {
      $0.iCloudSettingsClient.setEnabled = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.isSyncEnabled, false))) {
      $0.isSyncEnabled = false
      $0.isTogglingSync = true
    }
    await store.receive(.syncSettingResponse(enabled: false, succeeded: true)) {
      $0.isTogglingSync = false
    }
    #expect(saved.value == false)
  }

  @Test("동기화 저장소 구성에 실패하면 토글을 이전 값으로 되돌린다")
  func enableSyncStorageFailureRevertsToggle() async {
    let store = TestStore(initialState: ICloudSettingsFeature.State()) {
      ICloudSettingsFeature()
    } withDependencies: {
      $0.iCloudSettingsClient.accountStatus = { .available }
      $0.iCloudSettingsClient.setEnabled = { _ in throw ConfigurationError.failed }
    }

    await store.send(.binding(.set(\.isSyncEnabled, true))) {
      $0.isSyncEnabled = true
      $0.isTogglingSync = true
    }
    await store.receive(.enableSyncStatusResponse(.available))
    await store.receive(.syncSettingResponse(enabled: true, succeeded: false)) {
      $0.isSyncEnabled = false
      $0.isTogglingSync = false
      $0.alert = makeICloudSyncUnavailableAlert(
        .configurationUnavailable,
        retry: .retry,
        continueWithoutSync: .continueWithoutSync,
        openSystemSettings: .openSystemSettings
      )
    }
  }

  @Test("원격 변경이 감지되면 마지막 동기화 시각을 저장하고 카운트를 다시 조회한다")
  func remoteChangeUpdatesLastSyncedAtAndCounts() async {
    let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
    let savedDate = LockIsolated<Date?>(nil)
    let store = TestStore(initialState: ICloudSettingsFeature.State()) {
      ICloudSettingsFeature()
    } withDependencies: {
      $0.date = .constant(fixedDate)
      $0.iCloudSettingsClient.setLastSyncedAt = { savedDate.setValue($0) }
      $0.iCloudSettingsClient.syncedSecretCount = { 5 }
      $0.iCloudSettingsClient.syncedProjectCount = { 2 }
    }

    await store.send(.remoteChangeDetected) {
      $0.lastSyncedAt = fixedDate
    }
    await store.receive(.countsResponse(secretCount: 5, projectCount: 2)) {
      $0.syncedSecretCount = 5
      $0.syncedProjectCount = 2
    }
    #expect(savedDate.value == fixedDate)
  }

  @Test("카운트 조회가 실패하면 기존 카운트를 비운다")
  func countFailureClearsCounts() async {
    var initial = ICloudSettingsFeature.State()
    initial.syncedSecretCount = 5
    initial.syncedProjectCount = 2

    let store = TestStore(initialState: initial) {
      ICloudSettingsFeature()
    } withDependencies: {
      $0.iCloudSettingsClient.syncedSecretCount = { throw CountError.failed }
      $0.iCloudSettingsClient.syncedProjectCount = { 2 }
    }

    await store.send(.didTapSyncNow)
    await store.receive(.countsFailed) {
      $0.syncedSecretCount = nil
      $0.syncedProjectCount = nil
    }
  }

  private enum CountError: Error {
    case failed
  }

  private enum ConfigurationError: Error {
    case failed
  }
}
