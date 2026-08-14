// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - SecuritySettingsFeature

@Reducer
struct SecuritySettingsFeature {

  // MARK: - State

  @ObservableState
  struct State: Equatable {
    var isRequireAuthOnLaunchEnabled = true
    var isRequireAuthToCopyEnabled = true
  }

  // MARK: - Action

  enum Action: Equatable {
    case task
    case didToggleRequireAuthOnLaunch(Bool)
    case didToggleRequireAuthToCopy(Bool)
  }

  // MARK: - Dependencies

  @Dependency(\.settingsClient) var settingsClient

  // MARK: - Body

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        state.isRequireAuthOnLaunchEnabled = settingsClient.isRequireAuthOnLaunchEnabled()
        state.isRequireAuthToCopyEnabled = settingsClient.isRequireAuthToCopyEnabled()
        return .none

      case .didToggleRequireAuthOnLaunch(let enabled):
        state.isRequireAuthOnLaunchEnabled = enabled
        return .run { _ in settingsClient.setRequireAuthOnLaunchEnabled(enabled) }

      case .didToggleRequireAuthToCopy(let enabled):
        state.isRequireAuthToCopyEnabled = enabled
        return .run { _ in settingsClient.setRequireAuthToCopyEnabled(enabled) }
      }
    }
  }
}
