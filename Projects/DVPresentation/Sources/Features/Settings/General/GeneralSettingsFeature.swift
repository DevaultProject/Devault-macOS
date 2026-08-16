// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - GeneralSettingsFeature

@Reducer
public struct GeneralSettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var isLaunchAtLoginEnabled = false
    var defaultEnvironment: SecretEnvironment = .dev

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task

    // MARK: - Internal

    case launchAtLoginFailed(previousValue: Bool)
  }

  // MARK: - Dependencies

  @Dependency(\.generalSettingsClient) var generalSettingsClient

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .task:
        state.isLaunchAtLoginEnabled = generalSettingsClient.isLaunchAtLoginEnabled()
        state.defaultEnvironment = SecretEnvironment(
          rawValue: generalSettingsClient.defaultEnvironment()
        ) ?? .dev
        return .none

      case .binding(\.isLaunchAtLoginEnabled):
        let enabled = state.isLaunchAtLoginEnabled
        return .run { send in
          do {
            try generalSettingsClient.setLaunchAtLoginEnabled(enabled)
          } catch {
            await send(.launchAtLoginFailed(previousValue: !enabled))
          }
        }

      case .binding(\.defaultEnvironment):
        let environment = state.defaultEnvironment
        return .run { _ in generalSettingsClient.setDefaultEnvironment(environment.rawValue) }

      case .binding:
        return .none

      case .launchAtLoginFailed(let previousValue):
        // 시스템 로그인 항목 변경에 실패하면 표시값을 이전 상태로 되돌린다.
        state.isLaunchAtLoginEnabled = previousValue
        return .none

      }
    }
  }
}
