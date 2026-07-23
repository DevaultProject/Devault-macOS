// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

// MARK: - LockFeature

@Reducer
public struct LockFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public var isPostOnboarding: Bool

    public init(isPostOnboarding: Bool = false) {
      self.isPostOnboarding = isPostOnboarding
    }
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case didTapUnlock

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case unlockCompleted
    }
  }

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didTapUnlock:
        return .send(.delegate(.unlockCompleted))

      case .delegate:
        return .none
      }
    }
  }
}
