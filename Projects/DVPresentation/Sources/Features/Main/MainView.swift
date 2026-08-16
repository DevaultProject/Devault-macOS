// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - MainView

struct MainView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<MainFeature>

  // MARK: - Body

  var body: some View {
    content
      .dvScreenBackground()
      .task { store.send(.task) }
      .sheet(
        item: $store.scope(state: \.createProject, action: \.createProject)
      ) { createProjectStore in
        CreateProjectView(store: createProjectStore)
      }
      .overlay(alignment: .topTrailing) {
        lockButton
          .padding(16)
          .ignoresSafeArea(edges: .top)
      }
  }
}

// MARK: - Subviews

extension MainView {
    
  /// **`NavigationSplitView`는 하나뿐이다.** 생성 화면은 가운데 컬럼을 접어 2컬럼처럼 보이게 한다.
  ///
  /// 컬럼 수가 다른 두 `NavigationSplitView`는 타입이 달라 `if/else`로 교체하면 서브트리가 통째로
  /// 새로 만들어진다 — 사이드바까지 재생성되어 토글 버튼이 튀고 `.task`가 재실행돼 목록이 깜빡였다.
  @ViewBuilder
  private var content: some View {
    switch store.screen {
    case .settings:
      if let settingsStore = store.scope(state: \.settings, action: \.settings) {
        SettingsView(store: settingsStore)
      }

    case .browsing, .creating:
      NavigationSplitView {
        sidebarColumn
      } content: {
        contentColumn
      } detail: {
        detailArea
      }
      .navigationSplitViewStyle(.balanced)
      .toolbarBackground(.hidden, for: .windowToolbar)
    }
  }

  @ViewBuilder
  private var detailArea: some View {
    if store.screen == .creating {
      // 폼이 떠 있는 동안에도 타입 선택 State는 살아 있으므로 폼을 먼저 본다.
      if let createSecretStore = store.scope(state: \.createSecret, action: \.createSecret) {
        CreateSecretView(store: createSecretStore)
      } else if let selectStore = store.scope(state: \.selectSecretType, action: \.selectSecretType) {
        SelectSecretTypeView(store: selectStore)
      }
    } else {
      detailColumn
    }
  }

  private var sidebarColumn: some View {
    SidebarView(store: store.scope(state: \.sidebar, action: \.sidebar))
      .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 270)
  }

  /// 생성 중에는 폭 0으로 접혀 2컬럼처럼 보인다.
  ///
  /// 뷰를 없애거나 다른 modifier를 붙이면 뷰 타입이 달라져 위 주석의 재생성 문제가 돌아온다.
  /// 살려둔 채 **같은 modifier의 값만** 바꾼다.
  private var contentColumn: some View {
    let isCollapsed = store.screen == .creating
    return SecretListView(store: store.scope(state: \.secretList, action: \.secretList))
      .navigationTitle("")
      .opacity(isCollapsed ? 0 : 1)
      // 드래그 하한은 컬럼이 아니라 콘텐츠가 갖는다. 컬럼 `min`으로 주면 접힐 때
      // `width >= 300`과 `MaxSize <= 0`이 공존해 AppKit이 제약 충돌을 뱉는다.
      .frame(minWidth: isCollapsed ? 0 : 300)
      .navigationSplitViewColumnWidth(
        min: 0,
        ideal: isCollapsed ? 0 : 320,
        max: isCollapsed ? 0 : 350
      )
  }

  private var detailColumn: some View {
    Group {
      if let detailStore = store.scope(state: \.secretDetail, action: \.secretDetail) {
        SecretDetailView(store: detailStore)
      } else {
        Text(.module("No secret selected"))
          .dvFont(.captionLG)
          .foregroundStyle(Color.dv(.gray700))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .navigationTitle("")
    // max는 주지 않는다 — 컬럼이 창을 채우지 못하면 윈도우 배경이 양옆에 드러난다.
    // 폼 폭 상한은 컬럼이 아니라 `SecretDetailView` 안의 `formMaxWidth()`가 담당한다.
    .navigationSplitViewColumnWidth(min: 420, ideal: 480)
  }

  private var lockButton: some View {
    Button {
      store.send(.didTapLock)
    } label: {
      Image(systemName: "lock")
        .foregroundStyle(Color.dv(.vaultGreen))
        .dvFont(.headingLG)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(String.module("Lock App"))
  }
}

// MARK: - Preview

#if DEBUG

#Preview {
  MainView(
    store: Store(initialState: MainFeature.State()) {
      MainFeature()
    }
  )
}

#endif
