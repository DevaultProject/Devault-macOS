// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - SettingsFeature

@Reducer
public struct SettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var selectedCategory: SettingsCategory = .general

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case didSelectCategory(SettingsCategory)
    case didTapClose

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case closeRequested
    }
  }

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didSelectCategory(let category):
        state.selectedCategory = category
        return .none

      case .didTapClose:
        return .send(.delegate(.closeRequested))

      case .delegate:
        return .none
      }
    }
  }
}
