// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

// MARK: - SecretDetailFeature

@Reducer
public struct SecretDetailFeature {

    // MARK: - Mode

    public enum Mode: Equatable {
        /// 조회 모드: Text 전용 뷰 트리. 인터랙티브 컨트롤 없음.
        case viewing
        /// 수정 모드: 기존 SectionView 재사용. editFields 바인딩 있음.
        case editing
    }

    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        /// 원본 시크릿. 즐겨찾기·저장 성공 시 reducer가 교체한다.
        /// `internal(set)` — 모듈 외부(뷰)에서 바인딩 대상으로 쓸 수 없다.
        /// `SecretListFeature.State.secretsState`와 동일한 접근 수준.
        public internal(set) var secret: Secret
        public var mode: Mode = .viewing
        /// 수정 모드에서만 유효. viewing일 때는 반드시 nil.
        var editFields: SecretMetaFields?
        public var availableProjects: [Project] = []
        /// 이 Secret에 연결된 Project. `Secret` 엔티티에 프로젝트 정보가 없어 별도 조회한다.
        /// 조회 화면의 Project 필드 표시와, 수정 진입 시 `projectIds` 초기값에 함께 쓰인다.
        public var linkedProjects: [Project] = []
        public var isSaving = false
        public var isLoadingProjects = false
        /// 삭제 요청 진행 중. 진행 중에는 삭제 버튼을 비활성화한다.
        public var isDeleting = false
        /// 복호화된 payload. 진입 시에는 복호화하지 않으므로 `.idle`로 시작한다 —
        /// 사용자가 처음 reveal이나 복사를 요청할 때 비로소 `.loading`으로 넘어간다.
        public var payloadState: LoadingState<CreateSecretPayload, SecretUseCaseError> = .idle
        /// 마스킹이 해제된 payload 필드. 필드마다 따로 열고 닫는다.
        var revealedFields: Set<SecretFieldID> = []
        /// 마지막 reveal 인증 성공 시각. `RevealAuthPolicy.ttl` 안에서는 재인증하지 않는다.
        ///
        /// State에 두는 것이 정책의 일부다 — 다른 시크릿을 선택하면 `MainFeature`가 이 State를
        /// 새로 할당하므로 창이 자동으로 닫힌다("시크릿 변경 시 재인증").
        var revealAuthorizedAt: Date?
        /// 복호화가 끝나면 이어서 복사할 필드. 값이 없는 상태에서 복사를 누른 경우에만 채워진다.
        var pendingCopyField: SecretFieldID?
        @Presents public var alert: AlertState<Action.Alert>?

        public init(secret: Secret) {
            self.secret = secret
        }
    }

    // MARK: - Action

    public enum Action: BindableAction, Equatable {

        // MARK: View
        case task
        case binding(BindingAction<State>)
        case didTapClose
        /// payload 복호화 재시도. 인증 취소로 `.failed`가 된 뒤 다시 시도할 유일한 경로다.
        case didTapRetryReveal
        /// 필드의 눈 버튼. 여는 경우에만 인증이 필요할 수 있고, 닫는 것은 언제나 즉시 처리된다.
        case didTapToggleReveal(SecretFieldID)
        /// 필드의 복사 버튼. 복사 자체는 인증하지 않지만, 값이 아직 복호화되지 않았다면
        /// 복호화 때문에 인증이 필요할 수 있다.
        case didTapCopy(SecretFieldID)
        case didTapToggleLike
        case didTapDelete
        case didTapEdit
        case didTapCancelEdit
        case didTapSave

        // MARK: Internal
        case projectsResponse(Result<[Project], ProjectUseCaseError>)
        case linkedProjectsResponse(Result<[Project], SecretUseCaseError>)
        /// 복호화 응답. `revealing`은 이 복호화를 유발한 필드로, 성공하면 그 필드를 함께 연다.
        case payloadResponse(Result<CreateSecretPayload, SecretUseCaseError>, revealing: SecretFieldID?)
        /// 인증만 수행한 결과. payload를 이미 들고 있는데 창만 만료된 경우에 쓴다.
        case reauthenticateResponse(Result<Bool, Never>, revealing: SecretFieldID)
        /// 클립보드 복사 결과. 실패도 사용자에게 알린다 — 값이 복사된 줄 알고 붙여넣으면 더 혼란스럽다.
        case copyResponse(Result<Bool, Never>)
        case likeResponse(Result<Secret, SecretUseCaseError>)
        /// 앱 수준 사건. 정책이 무효화 대상으로 보면 인증 창과 열린 필드를 모두 닫는다.
        case lifecycleEvent(AppLifecycleEvent)
        case deleteResponse(Result<Secret, SecretUseCaseError>)

        // MARK: Child
        case alert(PresentationAction<Alert>)

        // MARK: Delegate
        case delegate(Delegate)

        public enum Alert: Equatable {
            case confirmDiscard
            case confirmDelete
        }

        public enum Delegate: Equatable {
            case closed
            case secretUpdated(Secret)
            case deleted(Secret.ID)
        }
    }

    // MARK: - Cancellation

    private enum CancelID {
        /// 즐겨찾기 연타 시 이전 요청을 취소해 응답 순서가 뒤바뀌는 것을 막는다.
        case like
        /// 재시도 연타 시 생체인증 프롬프트 요청이 겹쳐 쌓이는 것을 막는다.
        case reveal
    }

    // MARK: - Dependencies

    @Dependency(\.projectClient) var projectClient
    @Dependency(\.secretClient) var secretClient
    @Dependency(\.appLifecycleClient) var appLifecycleClient
    @Dependency(\.revealAuthPolicy) var revealAuthPolicy
    @Dependency(\.date.now) var now

    // MARK: - Init

    public init() {}

    // MARK: - Body

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoadingProjects = true

                var effects: [Effect<Action>] = [
                    .run { send in
                        do {
                            let projects = try await projectClient.fetchProjects()
                            await send(.projectsResponse(.success(projects)))
                        } catch is CancellationError {
                        } catch {
                            await send(.projectsResponse(.failure(.unexpected)))
                        }
                    },
                    .run { [id = state.secret.id] send in
                        do {
                            let projects = try await secretClient.fetchLinkedProjects(id)
                            await send(.linkedProjectsResponse(.success(projects)))
                        } catch is CancellationError {
                        } catch {
                            await send(.linkedProjectsResponse(.failure(SecretUseCaseError.map(error))))
                        }
                    },
                ]

                // 진입 시에는 복호화하지 않는다. payload 필드는 값과 무관하게 항상 마스킹되므로
                // 미리 풀어둘 이유가 없고, 화면을 여는 것만으로 인증을 요구하지 않기 위해서다.
                effects.append(
                    .run { send in
                        for await event in appLifecycleClient.events() {
                            await send(.lifecycleEvent(event))
                        }
                    }
                )
                return .merge(effects)

            // 복호화 실패 후 재시도. 어떤 필드가 유발했는지는 이미 잃었으므로 값만 다시 받아온다.
            case .didTapRetryReveal:
                state.payloadState = .loading
                return revealEffect(secret: state.secret, revealing: nil)

            // 디자인에서 close(×) 버튼을 제거했으므로 현재 이 액션을 발생시키는 UI 경로가 없다.
            // detail은 사이드바 전환·리스트 선택 해제(`secretSelected(nil)`)로 닫힌다.
            // 삭제 성공 후 닫기에서 재사용할 예정이라 액션과 delegate는 유지한다.
            case .didTapClose:
                return .send(.delegate(.closed))

            case .projectsResponse(.success(let projects)):
                state.isLoadingProjects = false
                state.availableProjects = projects
                return .none

            case .projectsResponse(.failure):
                state.isLoadingProjects = false
                state.alert = .projectsLoadFailed
                return .none

            case .linkedProjectsResponse(.success(let projects)):
                state.linkedProjects = projects
                return .none

            // 진입 시 복호화를 하지 않게 되면서 복호화 실패 alert와 겹칠 일이 없어졌다.
            // 필드는 빈 값으로 남고, 나머지 정보는 영향받지 않는다는 것을 문구로 알린다.
            case .linkedProjectsResponse(.failure):
                state.alert = .projectsLoadFailed
                return .none

            // 복호화는 인증을 통과해야만 성공하므로, 도착 자체가 인증 성공을 뜻한다.
            case .payloadResponse(.success(let payload), let revealing):
                state.payloadState = .loaded(payload)
                state.revealAuthorizedAt = now
                if let revealing {
                    state.revealedFields.insert(revealing)
                }
                return copyPendingFieldEffect(&state)

            case .payloadResponse(.failure(let error), _):
                state.payloadState = .failed(error)
                state.pendingCopyField = nil
                state.alert = .payloadRevealFailed(SecretDetailError.map(error))
                return .none

            case .reauthenticateResponse(.success(let didAuthenticate), let field):
                guard didAuthenticate else {
                    state.alert = .payloadRevealFailed(.authRequired)
                    return .none
                }
                state.revealAuthorizedAt = now
                state.revealedFields.insert(field)
                return .none

            case .copyResponse(.success(let didCopy)):
                guard !didCopy else { return .none }
                state.alert = .copyFailed
                return .none

            case .lifecycleEvent(let event):
                guard revealAuthPolicy.invalidates(on: event) else { return .none }
                // 값 자체는 메모리에 남겨둔다 — 다시 열 때 인증만 받으면 되고,
                // 복호화를 또 하는 것은 사용자에게 보이지 않는 비용이다.
                state.revealAuthorizedAt = nil
                state.revealedFields.removeAll()
                return .none

            // 닫는 것은 인증 대상이 아니다 — 노출을 줄이는 방향이라 언제나 즉시 처리한다.
            case .didTapToggleReveal(let field) where state.revealedFields.contains(field):
                state.revealedFields.remove(field)
                return .none

            case .didTapToggleReveal(let field):
                // 값이 아직 없으면 복호화가 필요하고, 복호화 경로가 인증까지 함께 수행한다.
                guard case .loaded = state.payloadState else {
                    state.payloadState = .loading
                    return revealEffect(secret: state.secret, revealing: field)
                }
                // 값은 있고 인증 창만 남았는지 확인한다. 열려 있으면 인증 없이 연다.
                guard !revealAuthPolicy.isAuthorized(since: state.revealAuthorizedAt, now: now) else {
                    state.revealedFields.insert(field)
                    return .none
                }
                return reauthenticateEffect(revealing: field)

            // 복사는 인증하지 않는다. 다만 값이 없으면 복호화가 필요하고, 그 경로가 인증을 탄다.
            case .didTapCopy(let field):
                guard case .loaded(let payload) = state.payloadState else {
                    state.pendingCopyField = field
                    state.payloadState = .loading
                    return revealEffect(secret: state.secret, revealing: nil)
                }
                return copyEffect(value: payload.value(for: field))

            case .didTapToggleLike:
                let liked = !state.secret.liked
                return .run { [id = state.secret.id] send in
                    do {
                        let updated = try await secretClient.setLiked(id, liked)
                        await send(.likeResponse(.success(updated)))
                    } catch is CancellationError {
                    } catch {
                        await send(.likeResponse(.failure(SecretUseCaseError.map(error))))
                    }
                }
                .cancellable(id: CancelID.like, cancelInFlight: true)

            case .likeResponse(.success(let updated)):
                state.secret = updated
                return .send(.delegate(.secretUpdated(updated)))

            case .likeResponse(.failure):
                state.alert = .likeFailed
                return .none

            case .didTapDelete:
                state.alert = .confirmDelete
                return .none

            case .alert(.presented(.confirmDelete)):
                state.isDeleting = true
                return .run { [id = state.secret.id] send in
                    do {
                        let deleted = try await secretClient.softDelete(id)
                        await send(.deleteResponse(.success(deleted)))
                    } catch is CancellationError {
                    } catch {
                        await send(.deleteResponse(.failure(SecretUseCaseError.map(error))))
                    }
                }

            case .deleteResponse(.success(let deleted)):
                state.isDeleting = false
                return .send(.delegate(.deleted(deleted.id)))

            case .deleteResponse(.failure):
                state.isDeleting = false
                state.alert = .deleteFailed
                return .none

            // 편집 모드는 후속 이슈 범위다. 상태 전이가 없으므로 헤더의 수정 버튼은
            // `isEditEnabled: false`로 비활성 렌더되고 Cancel / Save 컨트롤은 노출되지 않는다.
            // 여기서는 액션 case만 예약해 둔다.
            case .didTapEdit, .didTapCancelEdit, .didTapSave:
                return .none

            case .binding, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    // MARK: - Effects

    /// 인증 + 복호화. `revealPayload`가 둘을 함께 하므로 값이 아직 없을 때만 쓴다.
    /// - Parameter revealing: 이 복호화를 유발한 필드. 성공하면 함께 열린다. 재시도 경로에서는 `nil`.
    private func revealEffect(
        secret: Secret,
        revealing: SecretFieldID?
    ) -> Effect<Action> {
        .run { send in
            do {
                let payload = try await secretClient.revealPayload(secret)
                await send(.payloadResponse(.success(payload), revealing: revealing))
            } catch is CancellationError {
            } catch {
                await send(.payloadResponse(.failure(SecretUseCaseError.map(error)), revealing: revealing))
            }
        }
        .cancellable(id: CancelID.reveal, cancelInFlight: true)
    }

    /// 값은 이미 있고 인증 창만 만료된 경우. 다시 복호화하지 않고 인증만 받는다.
    /// 인증 실패·취소는 alert 없이 조용히 무시한다 — 사용자가 스스로 취소한 경우가 대부분이고,
    /// 반복 실패는 `AuthenticateUseCase`가 비정상 접근으로 따로 알린다.
    private func reauthenticateEffect(revealing field: SecretFieldID) -> Effect<Action> {
        .run { send in
            do {
                try await secretClient.authenticate("Reveal secret value")
                await send(.reauthenticateResponse(.success(true), revealing: field))
            } catch is CancellationError {
            } catch {
                await send(.reauthenticateResponse(.success(false), revealing: field))
            }
        }
        .cancellable(id: CancelID.reveal, cancelInFlight: true)
    }

    /// 복호화가 끝난 뒤 대기 중이던 복사를 이어서 수행한다.
    private func copyPendingFieldEffect(_ state: inout State) -> Effect<Action> {
        guard
            let field = state.pendingCopyField,
            case .loaded(let payload) = state.payloadState
        else {
            return .none
        }
        state.pendingCopyField = nil
        return copyEffect(value: payload.value(for: field))
    }

    /// 클립보드 쓰기·30초 자동 정리·반복 복사 감지는 UseCase가 수행한다.
    private func copyEffect(value: String) -> Effect<Action> {
        .run { send in
            do {
                try await secretClient.copySensitiveValue(value)
                await send(.copyResponse(.success(true)))
            } catch is CancellationError {
            } catch {
                await send(.copyResponse(.success(false)))
            }
        }
    }
}
