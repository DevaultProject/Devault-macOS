// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

// MARK: - OnboardingFeature

@Reducer
public struct OnboardingFeature {

  // MARK: - Step

  public enum Step: Equatable, CaseIterable {
    case welcome
    case security
    case icloudSync
    case syncEnabled
  }

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public var step: Step = .welcome
    public var isEnablingSync = false
    @Presents var alert: AlertState<Action.Alert>?

    public init(step: Step = .welcome) {
      self.step = step
    }

    var currentStepIndex: Int {
      switch step {
      case .welcome:     return 0
      case .security:    return 1
      case .icloudSync:  return 2
      case .syncEnabled: return 2
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

    // MARK: - Internal

    case touchIDAuthSucceeded
    case touchIDAuthFailed(UserAuthenticationError)
    case iCloudSyncStatusResponse(ICloudAccountStatus)
    case enableSyncCompleted

    // MARK: - Child

    case alert(PresentationAction<Alert>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case completed
    }

    public enum Alert: Equatable {
      case retry
      case continueWithoutSync
      case openSystemSettings
    }
  }

  // MARK: - Dependencies

  @Dependency(\.onboardingClient) var onboardingClient
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
        return .run { send in
          do {
            try await onboardingClient.enableTouchID()
            await send(.touchIDAuthSucceeded)
          } catch let error as UserAuthenticationError {
            await send(.touchIDAuthFailed(error))
          } catch {
            await send(.touchIDAuthFailed(.failed))
          }
        }

      case .touchIDAuthSucceeded:
        state.step = .icloudSync
        return .none

      case .touchIDAuthFailed(let error):
        state.alert = makeTouchIDFailedAlert(error)
        return .none

      case .didTapNotNow:
        state.isEnablingSync = true
        return continueWithoutICloudEffect()

      case .didTapEnableSync:
        state.isEnablingSync = true
        return .run { send in
          do {
            let status = try await onboardingClient.enableICloudSync()
            await send(.iCloudSyncStatusResponse(status))
          } catch {
            await send(.iCloudSyncStatusResponse(.configurationUnavailable))
          }
        }

      case .iCloudSyncStatusResponse(let status):
        guard status == .available else {
          state.isEnablingSync = false
          state.alert = makeICloudSyncFailedAlert(status)
          return .none
        }
        return .run { send in
          try? await clock.sleep(for: .seconds(0.5))
          await send(.enableSyncCompleted)
        }

      case .enableSyncCompleted:
        state.step = .syncEnabled
        return .run { send in
          try? await clock.sleep(for: .seconds(2))
          await send(.delegate(.completed))
        }

      case .alert(.presented(.retry)):
        return .send(.didTapEnableSync)

      case .alert(.presented(.continueWithoutSync)):
        state.isEnablingSync = true
        return continueWithoutICloudEffect()

      case .alert(.presented(.openSystemSettings)):
        return .run { _ in await onboardingClient.openICloudSystemSettings() }

      case .alert:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

// MARK: - Private

private extension OnboardingFeature {

  func makeTouchIDFailedAlert(_ error: UserAuthenticationError) -> AlertState<Action.Alert> {
    makeUserAuthenticationFailedAlert(title: String.module("Authentication failed"), error: error)
  }

  func makeICloudSyncFailedAlert(_ status: ICloudAccountStatus) -> AlertState<Action.Alert> {
    makeICloudSyncUnavailableAlert(
      status,
      retry: .retry,
      continueWithoutSync: .continueWithoutSync,
      openSystemSettings: .openSystemSettings
    )
  }

  func continueWithoutICloudEffect() -> Effect<Action> {
    .run { send in
      await onboardingClient.continueWithoutICloud()
      await send(.delegate(.completed))
    }
  }
}
