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

  // MARK: - Metrics

  private enum Metrics {
    static let screenFade: Animation = .easeInOut(duration: 0.25)
  }

  // MARK: - Body

  public var body: some View {
    content
      .animation(Metrics.screenFade, value: store.screen)
      // 진행 오버레이를 그리는 유일한 지점 (`.omc/GUIDELINES.md`).
      .windowBusyOverlay()
      .task { store.send(.task) }
  }
}

// MARK: - Subviews

extension AppView {

  /// **메인은 사라질 때 애니메이션하지 않는다(`removal: .identity`).** 잠기는 순간 서서히
  /// 흐려지면 그 시간 동안 시크릿 목록이 화면에 남는다.
  @ViewBuilder
  private var content: some View {
    if let store = store.scope(state: \.onboarding, action: \.onboarding) {
      OnboardingContainerView(store: store)
        .transition(.opacity)
    } else if let store = store.scope(state: \.locked, action: \.locked) {
      LockView(store: store)
        .transition(.opacity)
    } else if let store = store.scope(state: \.main, action: \.main) {
      MainView(store: store)
        .transition(.asymmetric(insertion: .opacity, removal: .identity))
    }
  }
}

// MARK: - Preview

#if DEBUG

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

#endif
