// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - AboutSettingsFeature

@Reducer
public struct AboutSettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var version = "-"
    var isShowingLicenses = false

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task
    case didTapOpenSourceLicenses
  }

  // MARK: - Dependencies

  @Dependency(\.aboutSettingsClient) var aboutSettingsClient

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .task:
        state.version = aboutSettingsClient.appVersion()
        return .none

      case .didTapOpenSourceLicenses:
        state.isShowingLicenses = true
        return .none
      }
    }
  }
}
