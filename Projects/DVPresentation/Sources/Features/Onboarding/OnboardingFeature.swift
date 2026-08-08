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
    case syncing
  }

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public var step: Step = .welcome
    @Presents var alert: AlertState<Action.Alert>?

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

    // MARK: - Internal

    case touchIDAuthSucceeded
    case touchIDAuthFailed(UserAuthenticationError)
    case iCloudSyncStatusResponse(ICloudAccountStatus)
    case syncingCompleted

    // MARK: - Child

    case alert(PresentationAction<Alert>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case completed
    }

    public enum Alert: Equatable {}
  }

  // MARK: - Dependencies

  @Dependency(\.onboardingClient) var onboardingClient

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
        state.step = .syncing
        return .run { send in
          let status = await onboardingClient.enableICloudSync()
          await send(.iCloudSyncStatusResponse(status))
        }

      case .iCloudSyncStatusResponse(let status):
        guard status == .available else {
          state.step = .icloudSync
          state.alert = makeICloudSyncUnavailableAlert(status)
          return .none
        }
        return .send(.syncingCompleted)

      case .syncingCompleted:
        return .send(.delegate(.completed))

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
    makeUserAuthenticationFailedAlert(title: "인증하지 못했어요", error: error)
  }

  // 지금은 상태별로 알럿 문구만 구분한다. 동기화 진행 상태 표시, 재시도 유도 등 온보딩 iCloud UX 전반은
  // 별도 이슈에서 다룰 예정이다.
  func makeICloudSyncUnavailableAlert(_ status: ICloudAccountStatus) -> AlertState<Action.Alert> {
    let message: String
    switch status {
    case .available:
      assertionFailure("iCloudSyncStatusResponse가 이미 .available을 걸러내므로 도달 불가")
      message = "다시 시도해주세요."
    case .noAccount:
      message = "설정 앱에서 iCloud 로그인 후 다시 시도해주세요."
    case .restricted:
      message = "기기의 iCloud 사용 제한 설정을 확인해주세요."
    case .temporarilyUnavailable:
      message = "잠시 후 다시 시도해주세요."
    case .networkUnavailable:
      message = "네트워크 연결을 확인하고 다시 시도해주세요."
    case .couldNotDetermine:
      message = "iCloud 상태를 확인하지 못했어요. 잠시 후 다시 시도해주세요."
    }
    return AlertState {
      TextState("iCloud 동기화를 사용할 수 없어요")
    } actions: {
      ButtonState(role: .cancel) { TextState("확인") }
    } message: {
      TextState(message)
    }
  }
}
