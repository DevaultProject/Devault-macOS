// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

// MARK: - SecretListFeature

@Reducer
public struct SecretListFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public let collection: SecretQuery.Collection
    /// `.project`일 때 표시할 프로젝트 이름. `SecretQuery.Collection.project`은 id만 가지고 있어서,
    /// 어떤 프로젝트인지 알고 있는 호출부(사이드바)가 이름을 함께 넘겨준다.
    public let projectName: String?
    public internal(set) var secretsState: LoadingState<IdentifiedArrayOf<Secret>, SecretUseCaseError> = .idle
    public internal(set) var selectedSecretID: Secret.ID?
    public internal(set) var searchText = ""
    public internal(set) var sort: SecretQuery.Sort = .recentlyAdded
    @Presents var destination: Destination.State?

    public init(collection: SecretQuery.Collection = .all, projectName: String? = nil) {
      self.collection = collection
      self.projectName = projectName
    }

    /// `.expired`는 "이미 지남 + N일 이내 예정"을 한 화면에서 섹션으로 나눠 보여준다.
    /// `SecretFetchDescriptorBuilder`의 `expired` predicate는 `expiresAt < referenceDate` 단일 비교라
    /// referenceDate를 `expiringSoonWindowDays`만큼 미래로 밀어서 두 범위를 한 번에 가져온다.
    /// 화면에 표시되는 `collection`(및 그 referenceDate)은 실제 "오늘"을 유지 — 섹션 분류 기준으로 View가 그대로 쓴다.
    var query: SecretQuery {
      let normalizedSearchText = searchText.isEmpty ? nil : searchText
      switch collection {
      case let .expired(referenceDate):
        let windowEnd = referenceDate.addingTimeInterval(
          TimeInterval(SecretListFeature.expiringSoonWindowDays) * 86_400
        )
        return SecretQuery(
          collection: .expired(referenceDate: windowEnd),
          searchText: normalizedSearchText,
          sort: .expiringSoon
        )
      default:
        return SecretQuery(collection: collection, searchText: normalizedSearchText, sort: sort)
      }
    }
  }

  /// Expired 탭에서 "예정" 섹션으로 함께 보여줄 최대 기간(일).
  static let expiringSoonWindowDays = 30

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task
    case didSelectSecret(id: Secret.ID?)
    case didChangeSearchText(String)
    case didSelectSort(SecretQuery.Sort)
    case didTapAddToProject(id: Secret.ID)
    case didTapDelete(id: Secret.ID)
    case didTapRecover(id: Secret.ID)
    case didTapDeleteForever(id: Secret.ID)

    // MARK: - Internal

    case secretsResponse(Result<[Secret], SecretUseCaseError>)
    case mutationResponse(Result<Secret.ID, SecretUseCaseError>)

    // MARK: - Child

    case destination(PresentationAction<Destination.Action>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case secretSelected(Secret.ID?)
    }
  }

  // MARK: - Destination

  @Reducer
  public enum Destination {
    case addToProject(AddToProjectFeature)
  }

  // MARK: - Dependencies

  @Dependency(\.secretClient) var secretClient
  @Dependency(\.continuousClock) var clock

  private enum CancelID {
    case fetch
  }

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
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

      case .didTapAddToProject(let id):
        state.destination = .addToProject(AddToProjectFeature.State(secretID: id))
        return .none

      case .didTapDelete(let id):
        return mutationEffect(id: id) { try await secretClient.softDelete(id) }

      case .didTapRecover(let id):
        return mutationEffect(id: id) { try await secretClient.restore(id) }

      case .didTapDeleteForever(let id):
        return mutationEffect(id: id) { try await secretClient.permanentlyDelete(id) }

      case .mutationResponse(.success):
        return fetchSecretsEffect(query: state.query, debounced: false)

      case .mutationResponse(.failure):
        return .none

      case .destination:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
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

  private func mutationEffect(id: Secret.ID, operation: @escaping () async throws -> Void) -> Effect<Action> {
    .run { send in
      do {
        try await operation()
        await send(.mutationResponse(.success(id)))
      } catch {
        await send(.mutationResponse(.failure(SecretUseCaseError.map(error))))
      }
    }
  }
}

// MARK: - Destination Equatable

// swift-composable-architecture는 @Reducer enum의 State/Action에 Equatable을 자동으로 붙이지 않는다 (공식 예제도 동일하게 명시적으로 붙임).
extension SecretListFeature.Destination.State: Equatable {}
extension SecretListFeature.Destination.Action: Equatable {}
