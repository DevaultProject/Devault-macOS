// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - GeneralSettingsFeature

@Reducer
struct GeneralSettingsFeature {

  // MARK: - State

  @ObservableState
  struct State: Equatable {
    var isLaunchAtLoginEnabled = false
    var defaultEnvironment: SecretEnvironment?
  }

  // MARK: - Action

  enum Action: Equatable {
    case task
    case didToggleLaunchAtLogin(Bool)
    case launchAtLoginFailed(previousValue: Bool)
    case didSelectDefaultEnvironment(SecretEnvironment?)
  }

  // MARK: - Dependencies

  @Dependency(\.settingsClient) var settingsClient

  // MARK: - Body

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        state.isLaunchAtLoginEnabled = settingsClient.isLaunchAtLoginEnabled()
        state.defaultEnvironment = settingsClient.defaultEnvironment()
          .flatMap(SecretEnvironment.init(rawValue:))
        return .none

      case .didToggleLaunchAtLogin(let enabled):
        let previous = state.isLaunchAtLoginEnabled
        state.isLaunchAtLoginEnabled = enabled
        return .run { send in
          do {
            try settingsClient.setLaunchAtLoginEnabled(enabled)
          } catch {
            await send(.launchAtLoginFailed(previousValue: previous))
          }
        }

      case .launchAtLoginFailed(let previousValue):
        // 로그인 항목 등록/해제(SMAppService)가 실패하면 표시값을 실제 상태로 되돌린다.
        state.isLaunchAtLoginEnabled = previousValue
        return .none

      case .didSelectDefaultEnvironment(let environment):
        state.defaultEnvironment = environment
        return .run { _ in settingsClient.setDefaultEnvironment(environment?.rawValue) }
      }
    }
  }
}
