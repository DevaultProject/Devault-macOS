// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture

// MARK: - AppView

public struct AppView: View {

  // MARK: - Properties

  @Bindable public var store: StoreOf<AppFeature>

  // MARK: - Init

  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }

  // MARK: - Body

  public var body: some View {
    content
      .task { store.send(.task) }
  }
}

// MARK: - Subviews

extension AppView {

  private var content: some View {
    MainView(store: store.scope(state: \.main, action: \.main))
  }
}

// MARK: - Preview

#Preview {
  AppView(
    store: Store(initialState: AppFeature.State()) {
      AppFeature()
    }
  )
}
