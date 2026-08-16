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
    @Presents var alert: AlertState<Action.Alert>?

    public init(collection: SecretQuery.Collection = .all, projectName: String? = nil) {
      self.collection = collection
      self.projectName = projectName
    }

    /// `.expired`는 "이미 지남 + N일 이내 예정"을 한 화면에서 섹션으로 나눠 보여준다.
    /// window 계산은 `SecretQuery.Collection.expiringWindow(from:)` 한 곳에만 두고 사이드바 개수 집계와 공유한다.
    /// 화면에 표시되는 `collection`(및 그 referenceDate)은 실제 "오늘"을 유지 — 섹션 분류 기준으로 View가 그대로 쓴다.
    var query: SecretQuery {
      let normalizedSearchText = searchText.isEmpty ? nil : searchText
      switch collection {
      case let .expired(referenceDate):
        return SecretQuery(
          collection: .expiringWindow(from: referenceDate),
          searchText: normalizedSearchText,
          sort: .expiringSoon
        )
      case .notice:
        // predicate가 이미 "지나지 않음 + window 이내"를 전부 검사하므로 window 변환이 필요 없다.
        // 임박한 것부터 보여주는 게 자연스러워 정렬은 고정한다(사용자가 바꿀 이유가 없는 화면).
        return SecretQuery(collection: collection, searchText: normalizedSearchText, sort: .expiringSoon)
      case .all, .liked, .deleted, .project:
        return SecretQuery(collection: collection, searchText: normalizedSearchText, sort: sort)
      }
    }
  }

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
    case didTapRetry
    /// 외부(예: SecretDetail의 즐겨찾기·삭제)에서 목록 갱신을 요청할 때 사용.
    /// `task`/`didTapRetry`와 달리 `secretsState`를 `.loading`으로 바꾸지 않아 목록이 깜빡이지 않는다 —
    /// 내부 mutation(`mutationResponse(.success)`)이 재조회하는 방식과 동일하다.
    case refresh

    // MARK: - Internal

    case secretsResponse(Result<[Secret], SecretUseCaseError>)
    case mutationResponse(Result<Secret.ID, SecretUseCaseError>)

    // MARK: - Child

    case destination(PresentationAction<Destination.Action>)
    case alert(PresentationAction<Alert>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case secretSelected(Secret.ID?)
      /// 삭제·복구·영구삭제·프로젝트 연결로 Secret 집합이 바뀌었음을 부모에게 알린다.
      /// 부모가 사이드바 개수를 다시 세는 근거가 된다.
      case secretsChanged
    }

    public enum Alert: Equatable {}
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
      case .task, .didTapRetry:
        state.secretsState = .loading
        return fetchSecretsEffect(query: state.query, debounced: false)

      case .refresh:
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

      // 두 효과는 서로 독립적이지만 `.merge`는 도착 순서를 보장하지 않아 테스트가 깨지기 쉽다.
      // 부모 갱신을 먼저 흘려보내고 재조회를 잇는다 (`.send`는 즉시 끝나므로 지연은 없다).
      case .mutationResponse(.success):
        return .concatenate(
          .send(.delegate(.secretsChanged)),
          fetchSecretsEffect(query: state.query, debounced: false)
        )

      case .mutationResponse(.failure):
        state.alert = AlertState {
          TextState("작업을 완료하지 못했어요")
        } actions: {
          ButtonState(role: .cancel) { TextState("확인") }
        } message: {
          TextState("잠시 후 다시 시도해주세요.")
        }
        return .none

      // 프로젝트 연결로 프로젝트별 개수가 바뀌므로 목록 갱신과 함께 부모에게도 알린다.
      case .destination(.presented(.addToProject(.delegate(.projectLinked)))):
        return .concatenate(
          .send(.delegate(.secretsChanged)),
          fetchSecretsEffect(query: state.query, debounced: false)
        )

      case .destination:
        return .none

      case .alert:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
    .ifLet(\.$alert, action: \.alert)
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
