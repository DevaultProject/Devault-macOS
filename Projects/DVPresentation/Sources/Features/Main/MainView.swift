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
    
  @ViewBuilder
  private var content: some View {
    if store.createSecret != nil || store.selectSecretType != nil {
      // 사이드바 + 시크릿 생성 폼/타입 선택 그리드 (2컬럼)
      NavigationSplitView {
        sidebarColumn
      } detail: {
        twoColumnDetail
      }
      .navigationSplitViewStyle(.balanced)
      .toolbarBackground(.hidden, for: .windowToolbar)
    } else {
      // 사이드바 + 시크릿 목록 + 상세 (3컬럼)
      NavigationSplitView {
        sidebarColumn
      } content: {
        contentColumn
      } detail: {
        detailColumn
      }
      .navigationSplitViewStyle(.balanced)
      .toolbarBackground(.hidden, for: .windowToolbar)
    }
  }

  @ViewBuilder
  private var twoColumnDetail: some View {
    if let createSecretStore = store.scope(state: \.createSecret, action: \.createSecret) {
      CreateSecretView(store: createSecretStore)
    } else if let selectStore = store.scope(state: \.selectSecretType, action: \.selectSecretType) {
      SelectSecretTypeView(store: selectStore)
    }
  }

  private var sidebarColumn: some View {
    SidebarView(store: store.scope(state: \.sidebar, action: \.sidebar))
      .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 270)
  }

  private var contentColumn: some View {
    SecretListView(store: store.scope(state: \.secretList, action: \.secretList))
      .navigationTitle("")
      .navigationSplitViewColumnWidth(min: 300, ideal: 320, max: 350)
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

#Preview {
  MainView(
    store: Store(initialState: MainFeature.State()) {
      MainFeature()
    }
  )
}
