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

  public enum Action: Equatable {

    // MARK: - View

    case task
    case didChangeColumnVisibility(NavigationSplitViewVisibility)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {}
  }

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        return .none

      case .didChangeColumnVisibility(let visibility):
        state.columnVisibility = visibility
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
