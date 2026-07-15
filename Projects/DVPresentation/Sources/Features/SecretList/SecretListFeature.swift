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
    let collection: SecretQuery.Collection
    var secretsState: LoadingState<IdentifiedArrayOf<Secret>, SecretUseCaseError> = .idle
    var selectedSecretID: Secret.ID?
    var searchText = ""
    var sort: SecretQuery.Sort = .recentlyAdded

    init(collection: SecretQuery.Collection = .all) {
      self.collection = collection
    }

    var query: SecretQuery {
      SecretQuery(collection: collection, searchText: searchText.isEmpty ? nil : searchText, sort: sort)
    }
  }

  // MARK: - Action

  enum Action: Equatable {

    // MARK: - View

    case task
    case didSelectSecret(id: Secret.ID?)
    case didChangeSearchText(String)
    case didSelectSort(SecretQuery.Sort)

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
  @Dependency(\.continuousClock) var clock

  private enum CancelID {
    case fetch
  }

  // MARK: - Init

  init() {}

  // MARK: - Body

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        state.secretsState = .loading
        return fetchSecretsEffect(query: state.query, debounced: false)

      case .didChangeSearchText(let text):
        state.searchText = text
        return fetchSecretsEffect(query: state.query, debounced: true)

      case .didSelectSort(let sort):
        state.sort = sort
        return fetchSecretsEffect(query: state.query, debounced: false)

      case .secretsResponse(.success(let secrets)):
        state.secretsState = .loaded(IdentifiedArray(uniqueElements: secrets))
        return .none

      case .secretsResponse(.failure(let error)):
        state.secretsState = .failed(error)
        return .none

      case .didSelectSecret(let id):
        state.selectedSecretID = id
        return .send(.delegate(.secretSelected(id)))

      case .delegate:
        return .none
      }
    }
  }

  // MARK: - Helpers

  private func fetchSecretsEffect(query: SecretQuery, debounced: Bool) -> Effect<Action> {
    .run { send in
      if debounced {
        try await clock.sleep(for: .milliseconds(300))
      }
      do {
        let secrets = try await secretClient.fetchByQuery(query)
        await send(.secretsResponse(.success(secrets)))
      } catch {
        await send(.secretsResponse(.failure(SecretUseCaseError.map(error))))
      }
    }
    .cancellable(id: CancelID.fetch, cancelInFlight: true)
  }
}
