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
    var onboarding: OnboardingContainerFeature.State?
    var locked: LockFeature.State?
    var main: MainFeature.State?

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task

    #if DEBUG
    /// 온보딩과 잠금을 모두 건너뛰고 곧바로 메인으로 진입한다. Debug 메뉴 전용.
    case debugSkipToMain
    #endif

    // MARK: - Child

    case onboarding(OnboardingContainerFeature.Action)
    case locked(LockFeature.Action)
    case main(MainFeature.Action)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {}
  }

  // MARK: - Dependencies

  @Dependency(\.appLaunchClient) var appLaunchClient

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

        if appLaunchClient.hasCompletedOnboarding() {
          state.locked = .init()
        } else {
          state.onboarding = .init()
        }
        return .merge(
          .run { _ in
            _ = await appLaunchClient.requestNotificationAuthorization()
          },
          .run { _ in
            await appLaunchClient.syncExpiryNotifications()
          }
        )

      #if DEBUG
      // 온보딩 완료 플래그를 세우지 않는다 — 다음 실행에서 온보딩이 다시 나와야
      // 실제 흐름을 계속 검증할 수 있고, 디버그 통로가 영구 상태로 굳지 않는다.
      case .debugSkipToMain:
        state.onboarding = nil
        state.locked = nil
        state.main = .init()
        return .none
      #endif

      case .onboarding(.delegate(.completed)):
        state.onboarding = nil
        state.main = .init()
        return .run { _ in appLaunchClient.setOnboardingCompleted() }

      case .onboarding:
        return .none

      case .locked(.delegate(.unlockCompleted)):
        state.locked = nil
        state.main = .init()
        return .none

      case .locked:
        return .none

      case .main(.delegate(.lockRequested)):
        state.main = nil
        state.locked = .init()
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
