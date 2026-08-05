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
  }
}

// MARK: - Subviews

extension MainView {

  @ViewBuilder
  private var content: some View {
    if let selectStore = store.scope(state: \.selectSecretType, action: \.selectSecretType) {
      // 사이드바 + 타입 선택 그리드 (2컬럼)
      NavigationSplitView {
        sidebarColumn
      } detail: {
        SelectSecretTypeView(store: selectStore)
      }
      .navigationSplitViewStyle(.balanced)
      .toolbarBackground(.hidden, for: .windowToolbar)
    } else {
      // 사이드바 + 시크릿 목록 + 상세 (3컬럼)
      NavigationSplitView(columnVisibility: $store.columnVisibility) {
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
    Text("Detail")
      .navigationTitle("")
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
