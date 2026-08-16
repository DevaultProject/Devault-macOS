// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import Testing

@testable import DVPresentation

@MainActor
@Suite("DataSettingsFeature")
struct DataSettingsFeatureTests {
  @Test("task는 현재 iCloud 동기화 상태를 읽어온다")
  func taskLoadsICloudSyncState() async {
    let store = TestStore(initialState: DataSettingsFeature.State()) {
      DataSettingsFeature()
    } withDependencies: {
      $0.dataSettingsClient.isICloudSyncEnabled = { true }
    }

    await store.send(.task) {
      $0.isICloudSyncEnabled = true
    }
  }

  @Test("삭제 버튼을 누르면 확인 alert를 띄운다")
  func deleteButtonShowsConfirmationAlert() async {
    let store = TestStore(initialState: DataSettingsFeature.State()) {
      DataSettingsFeature()
    }

    await store.send(.didTapDeleteAllData) {
      $0.alert = AlertState {
        TextState("Delete All Data")
      } actions: {
        ButtonState(role: .destructive, action: .confirmDelete) {
          TextState("Delete")
        }
        ButtonState(role: .cancel) {
          TextState("Cancel")
        }
      } message: {
        TextState("This will permanently delete all secrets and projects. This action cannot be undone.")
      }
    }
  }

  @Test("확인하면 삭제를 실행한다")
  func confirmingDeletesAllData() async {
    let called = LockIsolated(false)
    var initial = DataSettingsFeature.State()
    initial.alert = AlertState { TextState("Delete All Data") } actions: {
      ButtonState(role: .destructive, action: .confirmDelete) { TextState("Delete") }
    }

    let store = TestStore(initialState: initial) {
      DataSettingsFeature()
    } withDependencies: {
      $0.dataSettingsClient.deleteAllData = { called.setValue(true) }
    }

    await store.send(.alert(.presented(.confirmDelete))) {
      $0.alert = nil
      $0.isDeleting = true
    }
    await store.receive(.deleteSucceeded) {
      $0.isDeleting = false
    }
    #expect(called.value)
  }

  @Test("삭제가 실패하면 실패 alert를 띄운다")
  func deleteFailureShowsErrorAlert() async {
    var initial = DataSettingsFeature.State()
    initial.alert = AlertState { TextState("Delete All Data") } actions: {
      ButtonState(role: .destructive, action: .confirmDelete) { TextState("Delete") }
    }

    let store = TestStore(initialState: initial) {
      DataSettingsFeature()
    } withDependencies: {
      $0.dataSettingsClient.deleteAllData = { throw CancellationError() }
    }

    await store.send(.alert(.presented(.confirmDelete))) {
      $0.alert = nil
      $0.isDeleting = true
    }
    await store.receive(.deleteFailed) {
      $0.isDeleting = false
      $0.alert = AlertState {
        TextState("Couldn't delete data")
      } actions: {
        ButtonState(role: .cancel) { TextState("OK") }
      } message: {
        TextState("Please try again.")
      }
    }
  }
}
