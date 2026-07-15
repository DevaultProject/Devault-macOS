// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture

// MARK: - MainView

struct MainView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<MainFeature>

  // MARK: - Body

  var body: some View {
    content
      .task { store.send(.task) }
  }
}

// MARK: - Subviews

extension MainView {

  private var content: some View {
    NavigationSplitView(columnVisibility: $store.columnVisibility) {
      sidebar
    } content: {
      contentColumn
    } detail: {
      detailColumn
    }
    .navigationSplitViewStyle(.balanced)
    .toolbarBackground(.hidden, for: .windowToolbar)
  }

  private var sidebar: some View {
    Text("Sidebar")
  }

  private var contentColumn: some View {
    Text("Content")
      .navigationTitle("")
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
