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
    public struct State: Equatable, Identifiable {
        /// 원본 시크릿. 즐겨찾기·저장 성공 시 reducer가 교체한다.
        /// `internal(set)` — 모듈 외부(뷰)에서 바인딩 대상으로 쓸 수 없다.
        /// `SecretListFeature.State.secretsState`와 동일한 접근 수준.
        public internal(set) var secret: Secret
        /// `ifLet`이 시크릿 전환을 알아보게 하는 식별자.
        ///
        /// `MainFeature`는 다른 시크릿을 선택하면 이 State를 nil을 거치지 않고 곧바로 교체하는데,
        /// `ifLet`은 자식 State의 식별자가 달라질 때만 진행 중인 effect를 취소한다. 식별자가 없으면
        /// 두 State가 같은 것으로 보여 취소가 걸리지 않고, 늦게 도착한 A의 복호화 응답이 B의 State에
        /// 실려 인증한 적 없는 B에 A의 평문과 인증 창이 열린다.
        public var id: Secret.ID { secret.id }
        public var mode: Mode = .viewing
        /// 수정 모드에서만 유효. viewing일 때는 반드시 nil.
        var editFields: SecretMetaFields?
        /// 이 Secret에 연결된 Project. `Secret` 엔티티에 프로젝트 정보가 없어 별도 조회한다.
        /// 조회 화면의 Project 필드 표시와, 수정 진입 시 `projectIds` 초기값에 함께 쓰인다.
        public var linkedProjects: [Project] = []
        public var isSaving = false
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
        /// 평문 필드의 복사 버튼. 값이 이미 화면에 있으므로 복호화도 인증도 거치지 않고,
        /// 비밀이 아니므로 민감 값 복사 정책(자동 정리·반복 감지)도 타지 않는다.
        case didTapCopyPlainValue(String)
        case didTapToggleLike
        case didTapDelete
        case didTapEdit
        case didTapCancelEdit
        case didTapSave

        // MARK: Internal
        case linkedProjectsResponse(Result<[Project], SecretUseCaseError>)
        /// 복호화 응답. 복호화를 유발한 동작을 함께 싣는다 — 눈 버튼이면 `revealing`에 그 필드가,
        /// 복사 버튼이면 `thenCopy`에 그 필드가 담긴다. 둘이 동시에 차는 경우는 없다.
        ///
        /// 이어서 할 일을 State가 아니라 액션에 싣는 것은 **취소와 함께 사라지게 하려는 것**이다.
        /// 복호화는 `CancelID.reveal`을 공유해 나중 요청이 앞 요청을 취소하는데, State에 남겨두면
        /// 취소된 요청의 몫이 다음 응답에 얹혀 누르지도 않은 복사가 일어난다.
        case payloadResponse(
            Result<CreateSecretPayload, SecretUseCaseError>,
            revealing: SecretFieldID?,
            thenCopy: SecretFieldID?
        )
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
            // 진입 시에는 복호화하지 않는다. payload 필드는 값과 무관하게 항상 마스킹되므로
            // 미리 풀어둘 이유가 없고, 화면을 여는 것만으로 인증을 요구하지 않기 위해서다.
            case .task:
                return .merge(
                    .run { [id = state.secret.id] send in
                        do {
                            let projects = try await secretClient.fetchLinkedProjects(id)
                            await send(.linkedProjectsResponse(.success(projects)))
                        } catch is CancellationError {
                        } catch {
                            await send(.linkedProjectsResponse(.failure(SecretUseCaseError.map(error))))
                        }
                    },
                    .run { send in
                        for await event in appLifecycleClient.events() {
                            await send(.lifecycleEvent(event))
                        }
                    }
                )

            // 복호화 실패 후 재시도. 어떤 필드가 유발했는지는 이미 잃었으므로 값만 다시 받아온다.
            case .didTapRetryReveal:
                state.payloadState = .loading
                return revealEffect(secret: state.secret, revealing: nil, thenCopy: nil)

            // 디자인에서 close(×) 버튼을 제거했으므로 현재 이 액션을 발생시키는 UI 경로가 없다.
            // detail은 사이드바 전환·리스트 선택 해제(`secretSelected(nil)`)로 닫힌다.
            // 삭제 성공 후 닫기에서 재사용할 예정이라 액션과 delegate는 유지한다.
            case .didTapClose:
                return .send(.delegate(.closed))

            case .linkedProjectsResponse(.success(let projects)):
                state.linkedProjects = projects
                return .none

            // 진입 시 복호화를 하지 않게 되면서 복호화 실패 alert와 겹칠 일이 없어졌다.
            // 필드는 빈 값으로 남고, 나머지 정보는 영향받지 않는다는 것을 문구로 알린다.
            case .linkedProjectsResponse(.failure):
                state.alert = .projectsLoadFailed
                return .none

            // 복호화는 인증을 통과해야만 성공하므로, 도착 자체가 인증 성공을 뜻한다.
            case .payloadResponse(.success(let payload), let revealing, let thenCopy):
                state.payloadState = .loaded(payload)
                state.revealAuthorizedAt = now
                if let revealing {
                    state.revealedFields.insert(revealing)
                }
                guard let thenCopy else { return .none }
                return copyEffect(value: payload.value(for: thenCopy))

            case .payloadResponse(.failure(let error), _, _):
                state.payloadState = .failed(error)
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
                    return revealEffect(secret: state.secret, revealing: field, thenCopy: nil)
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
                    state.payloadState = .loading
                    return revealEffect(secret: state.secret, revealing: nil, thenCopy: field)
                }
                return copyEffect(value: payload.value(for: field))

            // 복호화를 기다릴 이유가 없다 — 값이 payload가 아니라 metadata·secret에서 왔다.
            case .didTapCopyPlainValue(let value):
                return copyPlainEffect(value: value)

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
    /// - Parameter thenCopy: 복호화가 끝나면 이어서 복사할 필드. 복사 버튼이 유발한 경우에만 채운다.
    private func revealEffect(
        secret: Secret,
        revealing: SecretFieldID?,
        thenCopy: SecretFieldID?
    ) -> Effect<Action> {
        .run { send in
            do {
                let payload = try await secretClient.revealPayload(secret)
                await send(.payloadResponse(.success(payload), revealing: revealing, thenCopy: thenCopy))
            } catch is CancellationError {
            } catch {
                await send(
                    .payloadResponse(
                        .failure(SecretUseCaseError.map(error)),
                        revealing: revealing,
                        thenCopy: thenCopy
                    )
                )
            }
        }
        .cancellable(id: CancelID.reveal, cancelInFlight: true)
    }

    /// 값은 이미 있고 인증 창만 만료된 경우. 다시 복호화하지 않고 인증만 받는다.
    /// 인증 실패·취소도 alert로 알린다 — 필드가 열리지 않은 이유를 알려주지 않으면
    /// 버튼이 고장난 것으로 보인다. 반복 실패는 `AuthenticateUseCase`가 비정상 접근으로 따로 알린다.
    private func reauthenticateEffect(revealing field: SecretFieldID) -> Effect<Action> {
        .run { send in
            do {
                try await secretClient.authenticate(AuthenticationReason.revealSecret)
                await send(.reauthenticateResponse(.success(true), revealing: field))
            } catch is CancellationError {
            } catch {
                await send(.reauthenticateResponse(.success(false), revealing: field))
            }
        }
        .cancellable(id: CancelID.reveal, cancelInFlight: true)
    }

    /// 민감 값 복사. 클립보드 쓰기·30초 자동 정리·반복 복사 감지는 UseCase가 수행한다.
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

    /// 평문 복사. 자동 정리도 반복 감지도 붙지 않는다 — 비밀이 아닌 값에 그 정책을 씌우면
    /// 붙여넣기 전에 클립보드가 비고, 오탐 보안 경고가 뜬다 (`SecretClient.copyPlainValue` 참조).
    private func copyPlainEffect(value: String) -> Effect<Action> {
        .run { send in
            do {
                try await secretClient.copyPlainValue(value)
                await send(.copyResponse(.success(true)))
            } catch is CancellationError {
            } catch {
                await send(.copyResponse(.success(false)))
            }
        }
    }
}
