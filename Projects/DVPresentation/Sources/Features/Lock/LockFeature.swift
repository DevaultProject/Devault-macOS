// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

// MARK: - LockFeature

@Reducer
public struct LockFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    @Presents var alert: AlertState<Action.Alert>?

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case didTapUnlock

    // MARK: - Internal

    case unlockAuthSucceeded
    case unlockAuthFailed(UserAuthenticationError)

    // MARK: - Child

    case alert(PresentationAction<Alert>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case unlockCompleted
    }

    public enum Alert: Equatable {}
  }

  // MARK: - Dependencies

  @Dependency(\.lockClient) var lockClient

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didTapUnlock:
        return .run { send in
          do {
            try await lockClient.unlock()
            await send(.unlockAuthSucceeded)
          } catch let error as UserAuthenticationError {
            await send(.unlockAuthFailed(error))
          } catch {
            await send(.unlockAuthFailed(.failed))
          }
        }

      case .unlockAuthSucceeded:
        return .send(.delegate(.unlockCompleted))

      case .unlockAuthFailed(let error):
        state.alert = makeUnlockFailedAlert(error)
        return .none

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

private extension LockFeature {

  func makeUnlockFailedAlert(_ error: UserAuthenticationError) -> AlertState<Action.Alert> {
    let message: String
    switch error {
    case .unavailable:
      message = "시스템 설정에서 로그인 암호가 설정되어 있는지 확인해주세요."
    case .cancelled:
      message = "다시 시도해주세요."
    case .failed:
      message = "다시 시도해주세요."
    }
    return AlertState {
      TextState("잠금을 해제하지 못했어요")
    } actions: {
      ButtonState(role: .cancel) { TextState("확인") }
    } message: {
      TextState(message)
    }
  }
}
