// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture

// MARK: - AppView

public struct AppView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<AppFeature>

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

  @ViewBuilder
  private var content: some View {
    if let store = store.scope(state: \.onboarding, action: \.onboarding) {
      OnboardingContainerView(store: store)
    } else if let store = store.scope(state: \.locked, action: \.locked) {
      LockView(store: store)
    } else if let store = store.scope(state: \.main, action: \.main) {
      MainView(store: store)
    }
  }
}

// MARK: - Preview

#Preview {
  AppView(
    store: Store(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.appLaunchClient.hasCompletedOnboarding = { false }
      $0.appLaunchClient.setOnboardingCompleted = { }
    }
  )
}
