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
        /// 복호화된 payload. .idle → .loading → .loaded / .failed 순서로 전이.
        public var payloadState: LoadingState<CreateSecretPayload, SecretUseCaseError> = .idle
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
        case didTapToggleLike
        case didTapDelete
        case didTapEdit
        case didTapCancelEdit
        case didTapSave

        // MARK: Internal
        case projectsResponse(Result<[Project], ProjectUseCaseError>)
        case linkedProjectsResponse(Result<[Project], SecretUseCaseError>)
        case payloadResponse(Result<CreateSecretPayload, SecretUseCaseError>)
        case likeResponse(Result<Secret, SecretUseCaseError>)
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

    // MARK: - Init

    public init() {}

    // MARK: - Body

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoadingProjects = true
                state.payloadState = .loading
                return .merge(
                    .run { send in
                        do {
                            let projects = try await projectClient.fetchProjects()
                            await send(.projectsResponse(.success(projects)))
                        } catch is CancellationError {
                        } catch {
                            await send(.projectsResponse(.failure(.unexpected)))
                        }
                    },
                    revealEffect(secret: state.secret),
                    .run { [id = state.secret.id] send in
                        do {
                            let projects = try await secretClient.fetchLinkedProjects(id)
                            await send(.linkedProjectsResponse(.success(projects)))
                        } catch is CancellationError {
                        } catch {
                            await send(.linkedProjectsResponse(.failure(SecretUseCaseError.map(error))))
                        }
                    }
                )

            // 프로젝트 목록은 이미 확보돼 있고 실패한 것은 복호화뿐이므로 reveal만 다시 태운다.
            case .didTapRetryReveal:
                state.payloadState = .loading
                return revealEffect(secret: state.secret)

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
                return .none

            case .linkedProjectsResponse(.success(let projects)):
                state.linkedProjects = projects
                return .none

            // 연결 프로젝트 조회 실패는 alert를 띄우지 않는다 — 부가 정보이고,
            // payload 복호화 실패 alert와 겹치면 사용자가 원인을 오해한다. 필드는 빈 값으로 남는다.
            case .linkedProjectsResponse(.failure):
                return .none

            case .payloadResponse(.success(let payload)):
                state.payloadState = .loaded(payload)
                return .none

            case .payloadResponse(.failure(let error)):
                state.payloadState = .failed(error)
                state.alert = .payloadRevealFailed(SecretDetailError.map(error))
                return .none

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

    /// 진입(`task`)과 재시도(`didTapRetryReveal`)가 같은 조회를 쓴다.
    /// `revealPayload`는 매번 생체인증을 타므로, 취소되면 재시도만으로 같은 지점부터 다시 진행돼야 한다.
    private func revealEffect(secret: Secret) -> Effect<Action> {
        .run { send in
            do {
                let payload = try await secretClient.revealPayload(secret)
                await send(.payloadResponse(.success(payload)))
            } catch is CancellationError {
            } catch {
                await send(.payloadResponse(.failure(SecretUseCaseError.map(error))))
            }
        }
        .cancellable(id: CancelID.reveal, cancelInFlight: true)
    }
}
