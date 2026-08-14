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
    case idleTimeoutReached

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
  @Dependency(\.settingsClient) var settingsClient
  @Dependency(\.idleMonitorClient) var idleMonitorClient

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

        let hasCompletedOnboarding = appLaunchClient.hasCompletedOnboarding()
        if hasCompletedOnboarding {
          state.locked = settingsClient.isRequireAuthOnLaunchEnabled() ? .init() : nil
          if state.locked == nil {
            state.main = .init()
          }
        } else {
          state.onboarding = .init()
        }

        // syncExpiryNotifications가 LiveRepositories.secret을 처음 건드려 ModelContainer를 그 순간의 iCloud 설정으로 고정시키므로, 아직 Secret이 없는 온보딩 전에는 건너뛴다.
        return .merge(
          .run { _ in
            _ = await appLaunchClient.requestNotificationAuthorization()
          },
          hasCompletedOnboarding
            ? .run { _ in await appLaunchClient.syncExpiryNotifications() }
            : .none,
          .run { send in
            for await idleSeconds in idleMonitorClient.idleSecondsStream() {
              let autoLockMinutes = settingsClient.autoLockMinutes()
              // 0분은 "사용 안 함"이므로 감시하지 않는다.
              guard autoLockMinutes > 0, idleSeconds >= Double(autoLockMinutes * 60) else { continue }
              await send(.idleTimeoutReached)
            }
          }
        )

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

      case .idleTimeoutReached:
        guard state.main != nil else { return .none }
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
