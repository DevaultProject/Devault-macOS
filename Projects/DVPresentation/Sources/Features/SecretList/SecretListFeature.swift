// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

// MARK: - SecretListFeature

@Reducer
struct SecretListFeature {

  // MARK: - State

  @ObservableState
  struct State: Equatable {
    var secrets: IdentifiedArrayOf<Secret> = []
    var selectedSecretID: Secret.ID?
    var isLoading = false
  }

  // MARK: - Action

  enum Action: Equatable {

    // MARK: - View

    case task
    case didSelectSecret(id: Secret.ID?)

    // MARK: - Internal

    case secretsResponse(Result<[Secret], SecretUseCaseError>)

    // MARK: - Child

    // MARK: - Delegate

    case delegate(Delegate)

    enum Delegate: Equatable {
      case secretSelected(Secret.ID?)
    }
  }

  // MARK: - Dependencies

  @Dependency(\.secretClient) var secretClient

  // MARK: - Init

  init() {}

  // MARK: - Body

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        state.isLoading = true
        return .run { send in
          do {
            let secrets = try await secretClient.fetchByQuery(SecretQuery())
            await send(.secretsResponse(.success(secrets)))
          } catch {
            await send(.secretsResponse(.failure(SecretUseCaseError.map(error))))
          }
        }

      case .secretsResponse(.success(let secrets)):
        state.isLoading = false
        state.secrets = IdentifiedArray(uniqueElements: secrets)
        return .none

      case .secretsResponse(.failure):
        state.isLoading = false
        return .none

      case .didSelectSecret(let id):
        state.selectedSecretID = id
        return .send(.delegate(.secretSelected(id)))

      case .delegate:
        return .none
      }
    }
  }
}
