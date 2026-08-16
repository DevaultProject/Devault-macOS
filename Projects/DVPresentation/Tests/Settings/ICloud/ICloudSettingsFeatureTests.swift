// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain
import Testing

@testable import DVPresentation

@MainActor
@Suite("ICloudSettingsFeature")
struct ICloudSettingsFeatureTests {
  @Test("task는 현재 설정값과 마지막 update 감지 시각을 읽고 계정 상태를 확인한다")
  func taskLoadsCurrentSettings() async {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let store = TestStore(initialState: ICloudSettingsFeature.State()) {
      ICloudSettingsFeature()
    } withDependencies: {
      $0.iCloudSettingsClient.isEnabled = { true }
      $0.iCloudSettingsClient.lastUpdateDetectedAt = { date }
      $0.iCloudSettingsClient.accountStatus = { .available }
      $0.iCloudSettingsClient.remoteChangeStream = { AsyncStream { $0.finish() } }
    }

    await store.send(.task) {
      $0.isSyncEnabled = true
      $0.isRefreshingStatus = true
      $0.lastUpdateDetectedAt = date
    }
    await store.receive(.refreshStatusResponse(.available)) {
      $0.isRefreshingStatus = false
      $0.accountStatus = .available
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
      $0.accountStatus = .available
    }
    await store.receive(.delegate(.storageDidSwitch))
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
        retry: .retryEnable,
        continueWithoutSync: .continueWithoutSync,
        openSystemSettings: .openSystemSettings
      )
    }
  }

  @Test("동기화 끄기는 데이터 보존 정책을 안내한 뒤 저장소 구성을 적용한다")
  func disableSyncConfirmsDataPolicyBeforeApplying() async {
    let saved = LockIsolated<Bool?>(nil)
    var initial = ICloudSettingsFeature.State()
    initial.isSyncEnabled = true

    let store = TestStore(initialState: initial) {
      ICloudSettingsFeature()
    } withDependencies: {
      $0.iCloudSettingsClient.setEnabled = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.isSyncEnabled, false))) {
      $0.isSyncEnabled = true
      $0.alert = AlertState {
        TextState("Turn Off iCloud Sync?")
      } actions: {
        ButtonState(role: .destructive, action: .confirmDisableSync) {
          TextState("Turn Off")
        }
        ButtonState(role: .cancel) {
          TextState("Cancel")
        }
      } message: {
        TextState(
          "Data on this Mac and in iCloud won't be deleted. Future changes on this Mac won't sync until iCloud Sync is turned on again."
        )
      }
    }
    await store.send(.alert(.presented(.confirmDisableSync))) {
      $0.alert = nil
      $0.isSyncEnabled = false
      $0.isTogglingSync = true
    }
    await store.receive(.syncSettingResponse(enabled: false, succeeded: true)) {
      $0.isTogglingSync = false
    }
    await store.receive(.delegate(.storageDidSwitch))
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
      $0.accountStatus = .configurationUnavailable
      $0.alert = makeICloudSyncUnavailableAlert(
        .configurationUnavailable,
        retry: .retryEnable,
        continueWithoutSync: .continueWithoutSync,
        openSystemSettings: .openSystemSettings
      )
    }
  }

  @Test("원격 변경이 감지되면 마지막 update 감지 시각을 저장한다")
  func remoteChangeUpdatesLastUpdateDetectedAt() async {
    let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
    let savedDate = LockIsolated<Date?>(nil)
    let store = TestStore(initialState: ICloudSettingsFeature.State()) {
      ICloudSettingsFeature()
    } withDependencies: {
      $0.date = .constant(fixedDate)
      $0.iCloudSettingsClient.setLastUpdateDetectedAt = { savedDate.setValue($0) }
    }

    await store.send(.remoteChangeDetected) {
      $0.lastUpdateDetectedAt = fixedDate
    }
    #expect(savedDate.value == fixedDate)
  }

  @Test("상태 새로고침에서 계정 오류가 확인되면 상태와 alert를 갱신한다")
  func refreshStatusFailureShowsAlert() async {
    var initialState = ICloudSettingsFeature.State()
    initialState.isSyncEnabled = true
    initialState.accountStatus = .available
    let store = TestStore(initialState: initialState) {
      ICloudSettingsFeature()
    } withDependencies: {
      $0.iCloudSettingsClient.accountStatus = { .networkUnavailable }
    }

    await store.send(.didTapRefreshStatus) {
      $0.isRefreshingStatus = true
    }
    await store.receive(.refreshStatusResponse(.networkUnavailable)) {
      $0.isRefreshingStatus = false
      $0.accountStatus = .networkUnavailable
      $0.alert = makeICloudSyncUnavailableAlert(
        .networkUnavailable,
        retry: .retryRefreshStatus,
        continueWithoutSync: nil,
        openSystemSettings: .openSystemSettings
      )
    }
  }

  private enum ConfigurationError: Error {
    case failed
  }
}
