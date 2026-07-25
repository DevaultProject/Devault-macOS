// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

// MARK: - AppFeature

@Reducer
public struct AppFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    // 세 프로퍼티 중 항상 하나만 non-nil — reducer 로직으로 불변식 보장
    public internal(set) var onboarding: OnboardingContainerFeature.State?
    public internal(set) var locked: LockFeature.State?
    public internal(set) var main: MainFeature.State?

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task

    // MARK: - Child

    case onboarding(OnboardingContainerFeature.Action)
    case locked(LockFeature.Action)
    case main(MainFeature.Action)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {}
  }

  // MARK: - Dependencies

  @Dependency(\.onboardingStatus) var onboardingStatus

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        state.onboarding = nil
        state.locked = nil
        state.main = nil
          
        if onboardingStatus.hasCompleted() {
          state.locked = .init(isPostOnboarding: false)
        } else {
          state.onboarding = .init()
        }
        return .none

      case .onboarding(.delegate(.completed)):
        state.onboarding = nil
        state.main = .init()
        onboardingStatus.setCompleted()
        return .none

      case .onboarding:
        return .none

      case .locked(.delegate(.unlockCompleted)):
        state.locked = nil
        state.main = .init()
        return .none

      case .locked:
        return .none

      case .main:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.onboarding, action: \.onboarding) {
      OnboardingContainerFeature()
    }
    .ifLet(\.locked, action: \.locked) {
      LockFeature()
    }
    .ifLet(\.main, action: \.main) {
      MainFeature()
    }
  }
}
