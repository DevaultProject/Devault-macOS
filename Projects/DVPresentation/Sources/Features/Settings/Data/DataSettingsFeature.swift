// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - DataSettingsFeature

@Reducer
public struct DataSettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var isICloudSyncEnabled = false
    var isDeleting = false
    @Presents var alert: AlertState<Action.Alert>?

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task
    case didTapDeleteAllData

    // MARK: - Internal

    case deleteSucceeded
    case deleteFailed

    // MARK: - Child

    case alert(PresentationAction<Alert>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Alert: Equatable {
      case confirmDelete
    }

    public enum Delegate: Equatable {
      case dataDeleted
    }
  }

  // MARK: - Dependencies

  @Dependency(\.dataSettingsClient) var dataSettingsClient

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        state.isICloudSyncEnabled = dataSettingsClient.isICloudSyncEnabled()
        return .none

      case .didTapDeleteAllData:
        state.alert = deleteConfirmationAlert
        return .none

      case .alert(.presented(.confirmDelete)):
        state.isDeleting = true
        return .run { send in
          do {
            try await dataSettingsClient.deleteAllData()
            await send(.deleteSucceeded)
          } catch {
            await send(.deleteFailed)
          }
        }

      case .deleteSucceeded:
        state.isDeleting = false
        return .send(.delegate(.dataDeleted))

      case .deleteFailed:
        state.isDeleting = false
        state.alert = deleteFailureAlert
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

extension DataSettingsFeature {

  private var deleteConfirmationAlert: AlertState<Action.Alert> {
    AlertState {
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
  }

  private var deleteFailureAlert: AlertState<Action.Alert> {
    AlertState {
      TextState(String.module("Couldn't delete data"))
    } actions: {
      ButtonState(role: .cancel) {
        TextState(String.module("OK"))
      }
    } message: {
      TextState(String.module("Please try again."))
    }
  }
}
