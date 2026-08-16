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
    public var isWindowCaptureBlockingEnabled = true

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task
    case inactivityTimeoutReached

    // MARK: - Internal

    case windowCaptureBlockingChanged(Bool)
    case iCloudRemoteChangeDetected
    case iCloudRemoteChangeHandled

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
  @Dependency(\.appSecurityClient) var appSecurityClient
  @Dependency(\.windowCaptureBlockerClient) var windowCaptureBlockerClient
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date.now) var now

  // MARK: - Init

  public init() {}

  // MARK: - Cancellation

  private enum CancelID {
    case inactivityWatch
    case windowCaptureSettingsWatch
    case iCloudRemoteChangeWatch
    case iCloudRemoteChangeHandling
  }

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
          state.locked = appSecurityClient.isRequireAuthOnLaunchEnabled() ? .init() : nil
          if state.locked == nil {
            state.main = .init()
          }
        } else {
          state.onboarding = .init()
        }

        // 온보딩에서 iCloud 사용 여부를 고르기 전에는 저장소를 지연 초기화한다.
        return .merge(
          .run { _ in
            _ = await appLaunchClient.requestNotificationAuthorization()
          },
          hasCompletedOnboarding
            ? .run { _ in await appLaunchClient.syncExpiryNotifications() }
            : .none,
          state.main != nil ? inactivityWatchEffect() : .none,
          windowCaptureSettingsWatchEffect(),
          iCloudRemoteChangeWatchEffect()
        )

      case let .windowCaptureBlockingChanged(isEnabled):
        state.isWindowCaptureBlockingEnabled = isEnabled
        return .none

      case .iCloudRemoteChangeDetected:
        let detectedAt = now
        return .run { send in
          do {
            try await clock.sleep(for: .seconds(1))
          } catch {
            return
          }
          appLaunchClient.setICloudLastUpdateDetectedAt(detectedAt)
          await appLaunchClient.syncExpiryNotifications()
          await send(.iCloudRemoteChangeHandled)
        }
        .cancellable(id: CancelID.iCloudRemoteChangeHandling, cancelInFlight: true)

      case .iCloudRemoteChangeHandled:
        guard state.main != nil else { return .none }
        return .send(.main(.iCloudRemoteChangeDetected))

      case .onboarding(.delegate(.completed)):
        state.onboarding = nil
        state.main = .init()
        return .merge(
          .run { _ in appLaunchClient.setOnboardingCompleted() },
          .run { _ in await appLaunchClient.syncExpiryNotifications() },
          inactivityWatchEffect()
        )

      case .onboarding:
        return .none

      case .locked(.delegate(.unlockCompleted)):
        state.locked = nil
        state.main = .init()
        return inactivityWatchEffect()

      case .locked:
        return .none

      case .main(.delegate(.lockRequested)):
        state.main = nil
        state.locked = .init()
        return .cancel(id: CancelID.inactivityWatch)

      case .inactivityTimeoutReached:
        guard state.main != nil else { return .none }
        state.main = nil
        state.locked = .init()
        return .cancel(id: CancelID.inactivityWatch)

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

// MARK: - Private

private extension AppFeature {
  /// Main 세션마다 앱 상호작용 감시를 새로 시작한다. 타임아웃 계산은 UseCase가 담당하며,
  /// 이 Effect는 타임아웃을 AppFeature의 잠금 Action으로 변환한다.
  func inactivityWatchEffect() -> Effect<Action> {
    .run { send in
      for await _ in appSecurityClient.inactivityTimeoutStream() {
        await send(.inactivityTimeoutReached)
      }
    }
    .cancellable(id: CancelID.inactivityWatch, cancelInFlight: true)
  }

  func windowCaptureSettingsWatchEffect() -> Effect<Action> {
    .run { send in
      for await isEnabled in windowCaptureBlockerClient.enabledStream() {
        await send(.windowCaptureBlockingChanged(isEnabled))
      }
    }
    .cancellable(id: CancelID.windowCaptureSettingsWatch, cancelInFlight: true)
  }

  func iCloudRemoteChangeWatchEffect() -> Effect<Action> {
    .run { send in
      for await _ in appLaunchClient.iCloudRemoteChangeStream() {
        await send(.iCloudRemoteChangeDetected)
      }
    }
    .cancellable(id: CancelID.iCloudRemoteChangeWatch, cancelInFlight: true)
  }
}
