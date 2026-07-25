// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

// MARK: - OnboardingContainerFeature

@Reducer
public struct OnboardingContainerFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var onboarding: OnboardingFeature.State?
    var lock: LockFeature.State?

    public init() {
      self.onboarding = .init()
    }

    var currentStepIndex: Int {
      if let onboarding { return onboarding.currentStepIndex }
      return OnboardingFeature.Step.allCases.count - 1
    }
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - Child

    case onboarding(OnboardingFeature.Action)
    case lock(LockFeature.Action)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case completed
    }
  }

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onboarding(.delegate(.completed)):
        state.onboarding = nil
        state.lock = .init()
        return .none

      case .onboarding:
        return .none

      case .lock(.delegate(.unlockCompleted)):
        return .send(.delegate(.completed))

      case .lock:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.onboarding, action: \.onboarding) {
      OnboardingFeature()
    }
    .ifLet(\.lock, action: \.lock) {
      LockFeature()
    }
  }
}
