// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain

// MARK: - GeneralSettingsFeature

@Reducer
public struct GeneralSettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var isLaunchAtLoginEnabled = false
    var launchAtLoginStatus: LaunchAtLoginStatus = .notRegistered
    var defaultEnvironment: SecretEnvironment = .dev

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task
    case didTapOpenLoginItemsSettings

    // MARK: - Internal

    case launchAtLoginFailed(previousValue: Bool)
    case launchAtLoginStatusChanged(LaunchAtLoginStatus)
  }

  // MARK: - Dependencies

  @Dependency(\.generalSettingsClient) var generalSettingsClient

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .task:
        let status = generalSettingsClient.launchAtLoginStatus()
        state.launchAtLoginStatus = status
        state.isLaunchAtLoginEnabled = status.isRegistered
        state.defaultEnvironment = SecretEnvironment(
          rawValue: generalSettingsClient.defaultEnvironment()
        ) ?? .dev
        return .none

      case .binding(\.isLaunchAtLoginEnabled):
        let enabled = state.isLaunchAtLoginEnabled
        return .run { send in
          do {
            let status = try generalSettingsClient.setLaunchAtLoginEnabled(enabled)
            await send(.launchAtLoginStatusChanged(status))
          } catch {
            await send(.launchAtLoginFailed(previousValue: !enabled))
          }
        }

      case .didTapOpenLoginItemsSettings:
        return .run { _ in generalSettingsClient.openLoginItemsSystemSettings() }

      case .binding(\.defaultEnvironment):
        let environment = state.defaultEnvironment
        return .run { _ in generalSettingsClient.setDefaultEnvironment(environment.rawValue) }

      case .binding:
        return .none

      case .launchAtLoginFailed(let previousValue):
        // 시스템 로그인 항목 변경에 실패하면 표시값을 이전 상태로 되돌린다.
        state.isLaunchAtLoginEnabled = previousValue
        return .none

      case .launchAtLoginStatusChanged(let status):
        state.launchAtLoginStatus = status
        state.isLaunchAtLoginEnabled = status.isRegistered
        return .none

      }
    }
  }
}
