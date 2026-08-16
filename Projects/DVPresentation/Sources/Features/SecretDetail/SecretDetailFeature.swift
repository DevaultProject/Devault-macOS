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

    // MARK: - RevealContinuation

    /// 복호화가 끝난 뒤 이어서 할 일.
    ///
    /// 이어서 할 일을 State가 아니라 **액션에 싣는 것**은 취소와 함께 사라지게 하려는 것이다.
    /// 복호화는 `CancelID.reveal`을 공유해 나중 요청이 앞 요청을 취소하는데, State에 남겨두면
    /// 취소된 요청의 몫이 다음 응답에 얹혀 누르지도 않은 동작이 일어난다.
    ///
    /// 하나만 찰 수 있다는 것을 **타입이 보장한다** — 이전에는 `revealing:`·`thenCopy:` 두 파라미터를
    /// 두고 "둘이 동시에 차는 경우는 없다"를 주석으로만 지켰다.
    public enum RevealContinuation: Equatable {
        /// 값만 받아온다. 재시도 경로처럼 어떤 필드가 유발했는지 잃은 경우.
        case none
        /// 눈 버튼이 유발했다. 성공하면 그 필드가 열린다.
        case reveal(SecretFieldID)
        /// 복사 버튼이 유발했다. 성공하면 이어서 복사한다.
        case copy(SecretFieldID)
        /// 수정 버튼이 유발했다. 성공하면 편집 모드로 들어간다.
        ///
        /// 편집 폼의 type-specific 필드는 평문에서만 만들 수 있어서(`secret.payload`는 암호문)
        /// **수정 진입이 복호화를, 따라서 인증을 탄다.** 실패하면 조회 모드에 남는다 —
        /// 인증을 취소했는데 편집 화면이 열려 있으면 안 된다.
        case edit
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
        /// 편집 진입 시점의 폼 스냅샷. **사용자가 폼에서 무엇을 건드렸는지**의 기준이다.
        /// 취소 시 확인 alert를 띄울지 판정하고, 저장 시 공통 필드·프로젝트 연결의 변경분을 가린다.
        var editFieldsBaseline: SecretMetaFields?
        /// 편집 진입 시점의 복호화 payload. **저장할 때 무엇을 다시 써야 하는지**의 기준이다.
        ///
        /// `editFieldsBaseline`과 따로 두는 이유는 둘의 쓰임이 다르기 때문이다. 전자만 있으면
        /// UI에 노출되지 않는 metadata 필드를 병합할 원본이 없고, 후자만 있으면 `projectIds`·`memo`처럼
        /// payload 밖에 있는 변경을 취소 확인에서 놓친다.
        /// `payloadState`와도 분리한다 — 편집 중 다른 필드를 reveal해도 병합 기준이 흔들리면 안 된다.
        var editPayloadBaseline: CreateSecretPayload?
        /// 이 Secret에 연결된 Project. `Secret` 엔티티에 프로젝트 정보가 없어 별도 조회한다.
        /// 조회 화면의 Project 필드 표시와, 수정 진입 시 `projectIds` 초기값에 함께 쓰인다.
        public var linkedProjects: [Project] = []
        /// 프로젝트 선택 드롭다운의 옵션. **편집 진입 시에만 로드한다** —
        /// 조회만 하는 사용자에게 전체 프로젝트 목록을 읽힐 이유가 없다.
        public var availableProjects: [Project] = []
        public var isLoadingProjects = false
        /// 저장 시도에서 누락된 필수 필드의 인라인 경고. 생성 화면과 같은 규칙으로 채운다.
        var validationErrors: [SecretFieldID: String] = [:]
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
        /// 프로젝트 생성 시트. 편집 폼의 SectionView가 `onCreateProject`로 연다.
        @Presents var createProject: CreateProjectFeature.State?

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
        /// 필드의 복사 버튼. Copy UseCase가 설정에 따라 인증하고, payload가 없으면 화면에
        /// 공개하지 않는 Copy 전용 경로로 먼저 복호화한다.
        case didTapCopy(SecretFieldID)
        /// 평문 필드의 복사 버튼. 값이 이미 화면에 있으므로 복호화도 인증도 거치지 않고,
        /// 비밀이 아니므로 민감 값 복사 정책(자동 정리·반복 감지)도 타지 않는다.
        case didTapCopyPlainValue(String)
        case didTapToggleLike
        case didTapDelete
        case didTapEdit
        case didTapCancelEdit
        case didTapSave
        /// 편집 폼의 프로젝트 필드에서 "새 프로젝트" 를 누른 경우.
        case didTapCreateProject

        // MARK: Internal
        case linkedProjectsResponse(Result<[Project], SecretUseCaseError>)
        /// 편집 폼의 프로젝트 선택 옵션. 조회 중에는 조회하지 않는다.
        case availableProjectsResponse(Result<[Project], ProjectUseCaseError>)
        /// 복호화 응답. 복호화를 유발한 동작을 `then`에 함께 싣는다 (``RevealContinuation`` 참조).
        case payloadResponse(
            Result<CreateSecretPayload, SecretUseCaseError>,
            then: RevealContinuation
        )
        /// 인증만 수행한 결과. payload를 이미 들고 있는데 창만 만료된 경우에 쓴다.
        case reauthenticateResponse(Result<Bool, Never>, revealing: SecretFieldID)
        /// 클립보드 복사 결과. 실패도 사용자에게 알린다 — 값이 복사된 줄 알고 붙여넣으면 더 혼란스럽다.
        case copyResponse(Result<Bool, Never>)
        case likeResponse(Result<Secret, SecretUseCaseError>)
        /// 저장 응답. 방금 저장한 payload를 함께 싣는다 — 성공 시 `payloadState`를 그 값으로 바꿔야
        /// 조회로 돌아갔을 때 눈 버튼이 저장 전 값을 보여주지 않는다.
        case saveResponse(Result<Secret, SecretUseCaseError>, saved: CreateSecretPayload)
        /// 앱 수준 사건. 정책이 무효화 대상으로 보면 인증 창과 열린 필드를 모두 닫는다.
        case lifecycleEvent(AppLifecycleEvent)
        case deleteResponse(Result<Secret, SecretUseCaseError>)

        // MARK: Child
        case alert(PresentationAction<Alert>)
        case createProject(PresentationAction<CreateProjectFeature.Action>)

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
                return revealEffect(secret: state.secret, then: .none)

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
            //
            // 다만 **복사가 유발한 복호화는 열람 인증 창을 열지 않는다.** 복사는 자체 정책을
            // 따로 갖고(`CopySensitiveValueUseCase`가 설정을 읽어 결정한다), 여기서 창을 열면
            // 복사 한 번에 누르지도 않은 열람 권한이 따라붙는다.
            case .payloadResponse(.success(let payload), let continuation):
                state.payloadState = .loaded(payload)
                switch continuation {
                case .none:
                    state.revealAuthorizedAt = now
                    return .none
                case .reveal(let field):
                    state.revealAuthorizedAt = now
                    state.revealedFields.insert(field)
                    return .none
                case .copy(let field):
                    return copyEffect(value: payload.value(for: field))
                case .edit:
                    beginEditing(&state, payload: payload)
                    return .none
                }

            case .payloadResponse(.failure(let error), _):
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
                    return revealEffect(secret: state.secret, then: .reveal(field))
                }
                // 값은 있고 인증 창만 남았는지 확인한다. 열려 있으면 인증 없이 연다.
                guard !revealAuthPolicy.isAuthorized(since: state.revealAuthorizedAt, now: now) else {
                    state.revealedFields.insert(field)
                    return .none
                }
                return reauthenticateEffect(revealing: field)

            // Copy 인증 여부는 `CopySensitiveValueUseCase`가 설정을 읽어 결정한다.
            case .didTapCopy(let field):
                guard case .loaded(let payload) = state.payloadState else {
                    state.payloadState = .loading
                    return loadPayloadForCopyEffect(secret: state.secret, field: field)
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

            // 편집 폼은 평문이 있어야 만들 수 있다. 값이 없으면 복호화(= 인증)를 먼저 타고,
            // 성공한 뒤에야 편집 모드로 들어간다 (`RevealContinuation.edit`).
            case .didTapEdit:
                // 헤더에서 수정 버튼이 사라지므로 편집 중에는 도달하지 않지만,
                // 상태 전이를 한곳에서 막아 두는 편이 안전하다.
                guard state.mode == .viewing else { return .none }
                state.isLoadingProjects = true
                let projects = availableProjectsEffect()

                // 값이 이미 있으면 인증 없이 들어간다. TTL은 보지 않는다 — 여기서 지키려는 것은
                // "값 없이 편집에 들어가지 않는다"이지 노출 통제가 아니고, 값은 이미 메모리에 있다.
                if case .loaded(let payload) = state.payloadState {
                    beginEditing(&state, payload: payload)
                    return projects
                }
                state.payloadState = .loading
                return .merge(revealEffect(secret: state.secret, then: .edit), projects)

            // 건드린 것이 없으면 확인 없이 나간다. 물어보는 것 자체가 성가신 확인이 된다.
            case .didTapCancelEdit:
                guard state.mode == .editing else { return .none }
                guard state.editFields == state.editFieldsBaseline else {
                    state.alert = .confirmDiscard
                    return .none
                }
                endEditing(&state)
                return .none

            case .alert(.presented(.confirmDiscard)):
                endEditing(&state)
                return .none

            case .availableProjectsResponse(.success(let projects)):
                state.isLoadingProjects = false
                state.availableProjects = projects
                return .none

            // 편집은 계속할 수 있게 둔다 — 프로젝트 연결만 못 바꿀 뿐 나머지 필드는 영향이 없다.
            case .availableProjectsResponse(.failure):
                state.isLoadingProjects = false
                state.availableProjects = []
                state.alert = .projectsLoadFailed
                return .none

            case .didTapCreateProject:
                state.createProject = CreateProjectFeature.State()
                return .none

            // 방금 만든 프로젝트를 목록에 얹는다. 전체 재조회는 하지 않는다 —
            // 편집 중인 폼이 그대로 있어야 하고, 필요한 정보는 delegate가 다 실어 준다.
            case .createProject(.presented(.delegate(.projectCreated(let project)))):
                state.availableProjects.append(
                    Project(id: project.id, name: project.name, createdAt: now, updatedAt: now)
                )
                return .none

            case .didTapSave:
                return handleSave(&state)

            case .saveResponse(.success(let updated), let saved):
                state.isSaving = false
                state.secret = updated
                // 저장한 평문을 그대로 들고 있으므로 조회로 돌아가 눈 버튼을 눌러도 재복호화가 필요 없다.
                state.payloadState = .loaded(saved)
                // 조회 모드의 기본 상태는 전부 마스킹이다. 편집을 마치고 돌아왔는데 열려 있으면 어긋난다.
                state.revealedFields.removeAll()
                // 조회 화면의 Project chip은 `linkedProjects`를 읽는다. 갱신하지 않으면 저장 직후
                // 이전 프로젝트가 그대로 남는다. 방금 저장한 목록은 손에 있으므로 재조회하지 않는다.
                if let fields = state.editFields,
                   Set(fields.projectIds) != Set(state.editFieldsBaseline?.projectIds ?? []) {
                    let selected = Set(fields.projectIds)
                    state.linkedProjects = state.availableProjects.filter { selected.contains($0.id) }
                }
                endEditing(&state)
                return .send(.delegate(.secretUpdated(updated)))

            // 편집 모드를 유지한다 — 조회로 되돌리면 사용자가 입력한 내용이 통째로 사라진다.
            case .saveResponse(.failure, _):
                state.isSaving = false
                state.alert = .updateFailed
                return .none

            case .binding, .alert, .delegate, .createProject:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$createProject, action: \.createProject) {
            CreateProjectFeature()
        }
    }

    // MARK: - Editing

    /// 편집 진입. 폼 초기값과 dirty 판정 기준 둘을 함께 세운다.
    private func beginEditing(_ state: inout State, payload: CreateSecretPayload) {
        let fields = SecretMetaFields(
            secret: state.secret,
            payload: payload,
            // 조회 화면은 chip 라벨 때문에 엔티티를 들고 있다. 폼은 ID만 쓴다.
            projectIds: state.linkedProjects.map(\.id)
        )
        state.editFields = fields
        state.editFieldsBaseline = fields
        state.editPayloadBaseline = payload
        state.validationErrors = [:]
        state.mode = .editing
    }

    /// 편집 종료. 편집 전용 상태를 한 번에 비운다 —
    /// 하나라도 남으면 다음 진입의 dirty 판정 기준이 어긋난다.
    private func endEditing(_ state: inout State) {
        state.mode = .viewing
        state.editFields = nil
        state.editFieldsBaseline = nil
        state.editPayloadBaseline = nil
        state.validationErrors = [:]
    }

    /// 저장. 변경 없음 판정 → 필수 필드 검증 → 다시 쓸 대상 결정 순이다.
    private func handleSave(_ state: inout State) -> Effect<Action> {
        guard state.mode == .editing,
              let fields = state.editFields,
              let baselineFields = state.editFieldsBaseline,
              let baselinePayload = state.editPayloadBaseline
        else { return .none }

        // 아무것도 바뀌지 않았으면 도메인을 부르지 않는다. 부르면 updatedAt만 갱신되어
        // 목록의 "최근 추가" 정렬이 이유 없이 흔들린다. 목록 재조회도 필요 없으니 delegate도 없다.
        guard fields != baselineFields else {
            endEditing(&state)
            return .none
        }

        // 서브타입은 수정 화면에서 바꿀 수 없으므로 저장된 값을 그대로 쓴다.
        // `resolvedSubType`을 거치는 이유는 `Secret.subType`이 optional이라서다 — 그대로 넘기면
        // 예전 데이터에서 `invalidTypeCombination`으로 떨어져 저장이 조용히 실패한다.
        let secretType = state.secret.secretType.creatableType
        let subType = secretType.resolvedSubType(state.secret.subType)

        switch fields.toCreateSecretPayload(
            secretType: secretType,
            subType: subType,
            preserving: baselinePayload
        ) {
        case .success(let payload):
            state.validationErrors = [:]
            state.isSaving = true
            let change = payload.contentChange(comparedTo: baselinePayload)
            let patch = Self.patch(from: fields, baseline: baselineFields, secretType: secretType, subType: subType)
            let projectIds = Self.projectIDs(from: fields, baseline: baselineFields)

            return .run { [id = state.secret.id] send in
                do {
                    let updated = try await secretClient.updateSecret(id, patch, change, projectIds)
                    await send(.saveResponse(.success(updated), saved: payload))
                } catch is CancellationError {
                } catch {
                    await send(.saveResponse(.failure(SecretUseCaseError.map(error)), saved: payload))
                }
            }

        case .failure(.missingRequired(let fieldIDs)):
            // 이전 시도의 잔존 경고를 지우고 이번 결과만 세운다. 생성 화면과 같은 규칙이다.
            state.validationErrors = [:]
            for fieldID in fieldIDs {
                state.validationErrors[fieldID] = .module("Required")
            }
            return .none

        // (secretType, subType)이 저장된 시크릿에서 오고 수정 화면이 바꾸지 않으므로 도달할 수 없다.
        case .failure(.invalidTypeCombination):
            return .none
        }
    }

    /// 바뀐 공통 필드만 `.set`으로 싣는다. 안 바뀐 것은 `.unchanged`로 두어 불필요한 write를 만들지 않는다.
    ///
    /// 비교를 폼 값이 아니라 `toSecretDraft` 결과로 하는 이유는 `""` → `nil` 접힘 같은 매핑 규칙을
    /// 여기서 한 벌 더 알지 않기 위해서다. 이름 trim과 만료일 23:59:59 고정은 도메인이 하므로
    /// 화면에서 맞추지 않는다.
    private static func patch(
        from fields: SecretMetaFields,
        baseline: SecretMetaFields,
        secretType: CreatableSecretType,
        subType: CreatableSecretSubType?
    ) -> SecretPatch {
        let draft = fields.toSecretDraft(secretType: secretType, subType: subType)
        let old = baseline.toSecretDraft(secretType: secretType, subType: subType)

        return SecretPatch(
            name: draft.name == old.name ? .unchanged : .set(draft.name),
            service: draft.service == old.service ? .unchanged : .set(draft.service),
            environment: draft.environment == old.environment ? .unchanged : .set(draft.environment),
            expiresAt: draft.expiresAt == old.expiresAt ? .unchanged : .set(draft.expiresAt),
            memo: draft.memo == old.memo ? .unchanged : .set(draft.memo)
        )
    }

    /// 연결이 바뀐 경우에만 `.set`으로 최종 목록을 싣는다. `.set`은 목록이 같아도 연결을 다시 조정한다.
    /// 순서만 다른 것은 변경이 아니다 — 드롭다운에서 고른 순서가 저장 여부를 바꾸면 안 된다.
    private static func projectIDs(
        from fields: SecretMetaFields,
        baseline: SecretMetaFields
    ) -> PatchField<[Project.ID]> {
        Set(fields.projectIds) == Set(baseline.projectIds) ? .unchanged : .set(fields.projectIds)
    }

    // MARK: - Effects

    /// 편집 폼의 프로젝트 선택 옵션을 읽어 온다.
    private func availableProjectsEffect() -> Effect<Action> {
        .run { send in
            do {
                let projects = try await secretClient.fetchProjects()
                await send(.availableProjectsResponse(.success(projects)))
            } catch is CancellationError {
            } catch {
                await send(.availableProjectsResponse(.failure(ProjectUseCaseError.map(error))))
            }
        }
    }

    /// 인증 + 복호화. `revealPayload`가 둘을 함께 하므로 값이 아직 없을 때만 쓴다.
    /// - Parameter then: 복호화가 끝나면 이어서 할 일 (``RevealContinuation``).
    private func revealEffect(
        secret: Secret,
        then continuation: RevealContinuation
    ) -> Effect<Action> {
        .run { send in
            do {
                let payload = try await secretClient.revealPayload(secret)
                await send(.payloadResponse(.success(payload), then: continuation))
            } catch is CancellationError {
            } catch {
                await send(.payloadResponse(.failure(SecretUseCaseError.map(error)), then: continuation))
            }
        }
        .cancellable(id: CancelID.reveal, cancelInFlight: true)
    }

    /// Copy에 필요한 payload만 복호화한다. 인증은 이어지는 `copySensitiveValue`가 설정을 읽어
    /// 결정하며, 이 응답은 Reveal 인증 유효시간을 갱신하지 않는다(`.copy` continuation).
    ///
    /// `revealEffect`와 나뉘어 있는 것은 **Client 호출이 다르기 때문**이다 —
    /// 이쪽은 `loadPayloadForCopy`, 저쪽은 `revealPayload`로 인증 정책 자체가 갈린다.
    private func loadPayloadForCopyEffect(
        secret: Secret,
        field: SecretFieldID
    ) -> Effect<Action> {
        .run { send in
            do {
                let payload = try await secretClient.loadPayloadForCopy(secret)
                await send(.payloadResponse(.success(payload), then: .copy(field)))
            } catch is CancellationError {
            } catch {
                await send(
                    .payloadResponse(
                        .failure(SecretUseCaseError.map(error)),
                        then: .copy(field)
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

    /// 민감 값 복사. 설정에 따른 인증, 클립보드 쓰기·자동 정리·반복 복사 감지는 UseCase가 수행한다.
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
