// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - DataSettingsFeature

@Reducer
struct DataSettingsFeature {

  // MARK: - State

  @ObservableState
  struct State: Equatable {
    var isDeleting = false
    @Presents var alert: AlertState<Action.Alert>?
  }

  // MARK: - Action

  enum Action: Equatable {
    case didTapDeleteAllData
    case deleteResponse(Result<Void, DeleteAllDataError>)
    case alert(PresentationAction<Alert>)

    enum Alert: Equatable {
      case confirmDelete
    }
  }

  /// alert가 Equatable을 요구하는데 실제 Error 타입은 그렇지 않으므로, "삭제 실패"라는
  /// 사실만 구분하면 되는 이 화면에서는 케이스가 없는 얇은 래퍼로 충분하다.
  enum DeleteAllDataError: Equatable {
    case failed
  }

  // MARK: - Dependencies

  @Dependency(\.settingsClient) var settingsClient

  // MARK: - Body

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didTapDeleteAllData:
        state.alert = AlertState {
          TextState(String.module("Delete All Data"))
        } actions: {
          ButtonState(role: .destructive, action: .confirmDelete) {
            TextState(String.module("Delete"))
          }
          ButtonState(role: .cancel) {
            TextState(String.module("Cancel"))
          }
        } message: {
          TextState(String.module("This will permanently delete all secrets and projects. This action cannot be undone."))
        }
        return .none

      case .alert(.presented(.confirmDelete)):
        state.isDeleting = true
        return .run { send in
          do {
            try await settingsClient.deleteAllData()
            await send(.deleteResponse(.success(())))
          } catch {
            await send(.deleteResponse(.failure(.failed)))
          }
        }

      case .deleteResponse(.success):
        state.isDeleting = false
        return .none

      case .deleteResponse(.failure):
        state.isDeleting = false
        state.alert = AlertState {
          TextState(String.module("Couldn't delete data"))
        } actions: {
          ButtonState(role: .cancel) { TextState(String.module("OK")) }
        } message: {
          TextState(String.module("Please try again."))
        }
        return .none

      case .alert:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}
