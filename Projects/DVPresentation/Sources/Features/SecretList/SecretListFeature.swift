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
    public internal(set) var projectName: String?
    public internal(set) var secretsState: LoadingState<IdentifiedArrayOf<Secret>, SecretUseCaseError> = .idle
    public internal(set) var selectedSecretID: Secret.ID?
    public internal(set) var searchText = ""
    public internal(set) var sort: SecretQuery.Sort = .recentlyAdded
    @Presents var alert: AlertState<Action.Alert>?

    public init(collection: SecretQuery.Collection = .all, projectName: String? = nil) {
      self.collection = collection
      self.projectName = projectName
    }

    /// 다른 대상을 보도록 바꾼다. **State를 직접 갈아끼우지 말고 이걸 쓴다.**
    ///
    /// 대상이 같으면 목록을 그대로 둔다. 새로 만들면 `secretsState`가 비는데 뷰의
    /// `.task(id: collection)`은 `collection`이 그대로라 다시 돌지 않아 빈 화면이 남는다.
    ///
    /// **데이터가 무효해진 경우에는 쓰지 않는다** — 저장소 전환은 이전 시크릿이 남으면 안 되므로
    /// 통째로 새로 만든다(`MainFeature.resetVaultContent`).
    mutating func retarget(to collection: SecretQuery.Collection, projectName: String? = nil) {
      guard self.collection == collection else {
        self = .init(collection: collection, projectName: projectName)
        return
      }
      if let projectName { self.projectName = projectName }
      selectedSecretID = nil
    }

    var query: SecretQuery {
      let normalizedSearchText = searchText.isEmpty ? nil : searchText
      switch collection {
      case .expired:
        return SecretQuery(
          collection: collection,
          searchText: normalizedSearchText,
          sort: SecretQuery.Sort(key: .expiry, direction: .ascending)
        )
      case .notice:
        // predicate가 이미 "지나지 않음 + window 이내"를 전부 검사하므로 window 변환이 필요 없다.
        // 임박한 것부터 보여주는 게 자연스러워 정렬은 고정한다(사용자가 바꿀 이유가 없는 화면).
        return SecretQuery(
          collection: collection,
          searchText: normalizedSearchText,
          sort: SecretQuery.Sort(key: .expiry, direction: .ascending)
        )
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

    case alert(PresentationAction<Alert>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case secretSelected(Secret.ID?)
      /// 삭제·복구·영구삭제·프로젝트 연결로 Secret 집합이 바뀌었음을 부모에게 알린다.
      /// 부모가 사이드바 개수를 다시 세는 근거가 된다.
      case secretsChanged
    }

    public enum Alert: Equatable {
      case confirmDeleteForever(id: Secret.ID)
    }
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
      // 이미 받아둔 목록이 있으면 비우지 않는다. `.task`는 최초 진입이 아니라 뷰가 다시
      // 만들어질 때마다 실행되므로(설정 화면 왕복 등) 비우면 목록이 사라졌다 나타난다.
      case .task:
        switch state.secretsState {
        case .loaded: break
        default: state.secretsState = .loading
        }
        return fetchSecretsEffect(query: state.query, debounced: false)

      // 재시도는 실패 화면에서만 눌리므로 되돌릴 목록이 없다.
      case .didTapRetry:
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

      case .didTapDelete(let id):
        return mutationEffect(id: id) { try await secretClient.softDelete(id) }

      case .didTapRecover(let id):
        return mutationEffect(id: id) { try await secretClient.restore(id) }

      case .didTapDeleteForever(let id):
        state.alert = deleteForeverConfirmationAlert(id: id)
        return .none

      case .alert(.presented(.confirmDeleteForever(let id))):
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

      case .alert:
        return .none

      case .delegate:
        return .none
      }
    }
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

  /// 되돌릴 수 없는 작업이라 실수로 누른 걸 걸러낸다.
  private func deleteForeverConfirmationAlert(id: Secret.ID) -> AlertState<Action.Alert> {
    AlertState {
      TextState(String.module("Delete Forever?"))
    } actions: {
      ButtonState(role: .destructive, action: .confirmDeleteForever(id: id)) {
        TextState(String.module("Delete Forever"))
      }
      ButtonState(role: .cancel) {
        TextState(String.module("Cancel"))
      }
    } message: {
      TextState(String.module("This action cannot be undone."))
    }
  }
}
