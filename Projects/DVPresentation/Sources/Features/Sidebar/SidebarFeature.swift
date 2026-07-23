// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

// MARK: - SidebarFilter

public enum SidebarFilter: Equatable, CaseIterable, Hashable {
  case all
  case starred
  case notice
  case expired
  case deleted

  var title: String {
    switch self {
    case .all:     "All"
    case .starred: "Star"
    case .notice:  "Notice"
    case .expired: "Expired"
    case .deleted: "Deleted"
    }
  }

  var icon: String {
    switch self {
    case .all:     "square.grid.2x2.fill"
    case .starred: "star.fill"
    case .notice:  "exclamationmark"
    case .expired: "clock.badge.xmark"
    case .deleted: "trash"
    }
  }

}

// MARK: - SidebarSelection

public enum SidebarSelection: Equatable {
  case filter(SidebarFilter)
  case project(Int)
}

// MARK: - SidebarFeature

@Reducer
public struct SidebarFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public internal(set) var selection: SidebarSelection = .filter(.all)
    public internal(set) var isProjectSectionExpanded: Bool = true

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task
    case didSelect(SidebarSelection)
    case didTapAddButton
    case didTapSettingsButton
    case didTapAddProject
    case didToggleProjectSection

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case selectionChanged(SidebarSelection)
      case addButtonTapped
      case settingsButtonTapped
      case addProjectTapped
    }
  }

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        return .none

      case .didSelect(let selection):
        state.selection = selection
        return .send(.delegate(.selectionChanged(selection)))

      case .didTapAddButton:
        return .send(.delegate(.addButtonTapped))

      case .didTapSettingsButton:
        return .send(.delegate(.settingsButtonTapped))

      case .didTapAddProject:
        return .send(.delegate(.addProjectTapped))

      case .didToggleProjectSection:
        state.isProjectSectionExpanded.toggle()
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
