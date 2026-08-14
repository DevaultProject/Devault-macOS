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
        return .send(.delegate(.completed))

      case .didTapEnableSync:
        state.isEnablingSync = true
        return .run { send in
          let status = await onboardingClient.enableICloudSync()
          await send(.iCloudSyncStatusResponse(status))
        }

      case .iCloudSyncStatusResponse(let status):
        guard status == .available else {
          state.isEnablingSync = false
          state.alert = makeICloudSyncUnavailableAlert(status)
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
        return .send(.delegate(.completed))

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

  /// 상태별로 문구를 구분하고, 재시도 가능한 상태에는 재시도 버튼을, 계정 문제로 인한 상태에는
  /// 시스템 설정 앱을 바로 여는 버튼을 추가한다. 어떤 상태든 iCloud 없이 계속 진행할 수 있다.
  func makeICloudSyncUnavailableAlert(_ status: ICloudAccountStatus) -> AlertState<Action.Alert> {
    let message: String
    switch status {
    case .available:
      assertionFailure("iCloudSyncStatusResponse가 이미 .available을 걸러내므로 도달 불가")
      message = String.module("Please try again.")
    case .noAccount:
      message = String.module("Sign in to iCloud in System Settings, then try again.")
    case .restricted:
      message = String.module("Check your device's iCloud usage restrictions.")
    case .temporarilyUnavailable:
      message = String.module("Please try again in a moment.")
    case .networkUnavailable:
      message = String.module("Check your network connection and try again.")
    case .configurationUnavailable:
      // 앱 배포 설정(컨테이너 식별자, entitlement) 문제라 사용자가 재시도해도 해결되지 않음.
      message = String.module("iCloud sync isn't available right now. Please try again later.")
    case .couldNotDetermine:
      message = String.module("Couldn't determine iCloud status. Please try again in a moment.")
    }
    let canRetry = status != .configurationUnavailable
    let canOpenSettings = status == .noAccount || status == .restricted
    return AlertState {
      TextState(String.module("iCloud sync isn't available"))
    } actions: {
      if canRetry {
        ButtonState(action: .retry) { TextState(String.module("Try Again")) }
      }
      if canOpenSettings {
        ButtonState(action: .openSystemSettings) { TextState(String.module("Open System Settings")) }
      }
      ButtonState(action: .continueWithoutSync) { TextState(String.module("Continue Without iCloud")) }
      ButtonState(role: .cancel) { TextState(String.module("OK")) }
    } message: {
      TextState(message)
    }
  }
}
