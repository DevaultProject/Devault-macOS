// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture

// MARK: - AppFeature

@Reducer
public struct AppFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var main: MainFeature.State = .init()

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task

    // MARK: - Child

    case main(MainFeature.Action)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {}
  }

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Scope(state: \.main, action: \.main) {
      MainFeature()
    }
    Reduce { state, action in
      switch action {
      case .task:
        return .none

      case .main:
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
