// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

// MARK: - OnboardingFeature

@Reducer
public struct OnboardingFeature {

  // MARK: - Step

  public enum Step: Equatable, CaseIterable {
    case welcome
    case security
    case icloudSync
    case syncing
  }

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public var step: Step = .welcome

    public init(step: Step = .welcome) {
      self.step = step
    }

    var currentStepIndex: Int {
      switch step {
      case .welcome:    return 0
      case .security:   return 1
      case .icloudSync: return 2
      case .syncing:    return 2
      }
    }
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case didTapStart
    case didTapEnableTouchID
    case didTapNotNow
    case didTapEnableSync
    case syncingCompleted

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case completed
    }
  }

  // MARK: - Dependencies

  @Dependency(\.continuousClock) var clock

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didTapStart:
        state.step = .security
        return .none

      case .didTapEnableTouchID:
        state.step = .icloudSync
        return .none

      case .didTapNotNow:
        return .send(.delegate(.completed))

      case .didTapEnableSync:
        state.step = .syncing
        return .run { send in
          // TODO: 실제 iCloud sync 완료 콜백으로 교체
          try await clock.sleep(for: .seconds(3))
          await send(.syncingCompleted)
        }

      case .syncingCompleted:
        return .send(.delegate(.completed))

      case .delegate:
        return .none
      }
    }
  }
}
