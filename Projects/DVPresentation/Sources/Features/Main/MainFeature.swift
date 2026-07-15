// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture

// MARK: - MainFeature

@Reducer
public struct MainFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public var columnVisibility: NavigationSplitViewVisibility = .all

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {}
  }

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
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
