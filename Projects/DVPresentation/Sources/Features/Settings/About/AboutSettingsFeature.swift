// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - AboutSettingsFeature

@Reducer
public struct AboutSettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var version = "-"

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task
  }

  // MARK: - Dependencies

  @Dependency(\.aboutSettingsClient) var aboutSettingsClient

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        state.version = aboutSettingsClient.appVersion()
        return .none
      }
    }
  }
}
