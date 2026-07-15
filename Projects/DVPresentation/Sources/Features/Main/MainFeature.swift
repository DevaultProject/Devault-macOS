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
    var sidebar: SidebarFeature.State = .init()

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task

    // MARK: - Child

    case sidebar(SidebarFeature.Action)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {}
  }

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Scope(state: \.sidebar, action: \.sidebar) {
      SidebarFeature()
    }
    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .task:
        return .none

      case .sidebar(.delegate(let delegate)):
        return handleSidebarDelegate(&state, delegate: delegate)

      case .sidebar:
        return .none

      case .delegate:
        return .none
      }
    }
  }
}

// MARK: - Private

extension MainFeature {

  private func handleSidebarDelegate(
    _ state: inout State,
    delegate: SidebarFeature.Action.Delegate
  ) -> Effect<Action> {
    switch delegate {
    case .selectionChanged:
      return .none

    case .addButtonTapped:
      return .none

    case .settingsButtonTapped:
      return .none

    case .addProjectTapped:
      return .none
    }
  }
}
