// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Testing

@testable import DVPresentation

@MainActor
@Suite("SettingsFeature")
struct SettingsFeatureTests {
  @Test("카테고리를 선택하면 selectedCategory가 바뀐다")
  func selectingCategoryUpdatesSelectedCategory() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    await store.send(.binding(.set(\.selectedCategory, .security))) {
      $0.selectedCategory = .security
    }
  }

  @Test("닫기 버튼을 누르면 closeRequested 델리게이트를 보낸다")
  func closeButtonSendsCloseRequestedDelegate() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    await store.send(.didTapClose)
    await store.receive(.delegate(.closeRequested))
  }

  @Test("iCloud 저장소 전환을 부모에게 전달한다")
  func storageSwitchIsForwardedToParent() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    await store.send(.icloud(.delegate(.storageDidSwitch)))
    await store.receive(.delegate(.storageDidSwitch))
  }

  @Test("전체 데이터 삭제를 부모에게 전달한다")
  func dataResetIsForwardedToParent() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    await store.send(.data(.delegate(.dataDeleted)))
    await store.receive(.delegate(.vaultDataReset))
  }
}
