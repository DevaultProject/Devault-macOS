// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVCore
import DVDomain
import Foundation

// MARK: - CreateSecretFeature

@Reducer
struct CreateSecretFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {

        /// 이전 화면에서 주입되는 SecretType. 이 화면 안에서는 변경 불가.
        let secretType: CreatableSecretType

        var selectedSubType: CreatableSecretSubType?

        var meta: SecretMetaFields

        var availableProjects: [Project] = []

        /// 도메인 매핑 실패로 누락된 필드에 대한 인라인 경고. Save 시도 시 세팅.
        var validationErrors: [SecretMetaFields.FieldID: String] = [:]

        /// "Auto-detected: <service>" 인라인 힌트. 감지 엔진에서 채워짐 (필드별 단일 문자열).
        /// TODO(#41-followup): 감지 엔진 wiring + SectionView가 `trailingHint(.detected)`로 소비하는 지점에서 이 필드 갱신.
        var detectedServices: [SecretMetaFields.FieldID: String] = [:]

        /// 감지 엔진이 넘겨준 service chip 후보 목록. `ServicesFieldView`가 chip으로 표시.
        var serviceCandidates: [String] = []

        var isSaving = false

        @Presents var alert: AlertState<Action.Alert>?

        /// 프로젝트 생성 시트 State. `didTapCreateProject` 시 세팅되어 sheet 노출.
        @Presents var createProject: CreateProjectFeature.State?

        init(secretType: CreatableSecretType) {
            let initialSubType = secretType.availableSubTypes.first
            self.secretType = secretType
            self.selectedSubType = initialSubType
            self.meta = SecretMetaFields(
                content: .default(for: secretType, subType: initialSubType)
            )
        }

        /// Create 버튼의 disable/enable 판정.
        /// 필수 필드 검증은 `didTapSave`가 `handleSave`에서 수행해 `validationErrors`를 채운다 —
        /// 여기서 사전 차단하면 인라인 warning이 절대 안 뜨므로 저장 중 재클릭만 막는다.
        var isSaveEnabled: Bool {
            !isSaving
        }
    }

    // MARK: - Action

    enum Action: BindableAction, Equatable {

        // MARK: - View

        case task
        case binding(BindingAction<State>)
        case didTapCancel
        case didTapSave
        case didTapCreateProject

        // MARK: - Internal

        case projectsResponse(Result<[Project], ProjectUseCaseError>)
        case saveResponse(Result<Secret, SecretUseCaseError>)
        /// 감지 엔진이 후보 서비스를 넘겨주면 `state.serviceCandidates`에 저장.
        case didDetectServiceCandidates([String])

        // MARK: - Child

        case alert(PresentationAction<Alert>)
        case createProject(PresentationAction<CreateProjectFeature.Action>)

        // MARK: - Delegate

        case delegate(Delegate)

        enum Alert: Equatable {
            case confirmCancel
        }

        enum Delegate: Equatable {
            case secretCreated(Secret.ID)
            case cancelled
        }
    }

    // MARK: - Dependencies

    @Dependency(\.secretManagementClient) var secretManagementClient
    @Dependency(\.projectClient) var projectClient

    // MARK: - Init

    init() {}

    // MARK: - Body

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            // MARK: View

            case .task:
                return .run { send in
                    do {
                        let projects = try await projectClient.fetchProjects()
                        await send(.projectsResponse(.success(projects)))
                    } catch {
                        let mapped = (error as? ProjectUseCaseError) ?? .unexpected
                        await send(.projectsResponse(.failure(mapped)))
                    }
                }

            case .binding(\.selectedSubType):
                state.meta.content = .default(
                    for: state.secretType,
                    subType: state.selectedSubType
                )
                state.validationErrors = [:]
                return .none

            case .binding:
                return .none

            case .didTapCancel:
                state.alert = .confirmCancel
                return .none

            case .didTapSave:
                return handleSave(state: &state)

            case .didTapCreateProject:
                state.createProject = CreateProjectFeature.State()
                return .none

            // MARK: Internal

            case .projectsResponse(.success(let projects)):
                state.availableProjects = projects
                return .none

            case .projectsResponse(.failure):
                state.availableProjects = []
                // TODO(#41-followup): 재시도/오프라인 배지 등 상세 처리는 후속 작업에서 대체.
                state.alert = .projectLoadFailed
                return .none

            case .saveResponse(.success(let secret)):
                state.isSaving = false
                return .send(.delegate(.secretCreated(secret.id)))

            case .saveResponse(.failure):
                state.isSaving = false
                // TODO(#41-followup): 저장 실패를 사용자에게 표시 (alert or 인라인 에러 state). 현재는 isSaving만 해제.
                return .none

            case .didDetectServiceCandidates(let candidates):
                state.serviceCandidates = candidates
                return .none

            // MARK: Child

            case .alert(.presented(.confirmCancel)):
                return .send(.delegate(.cancelled))

            case .alert:
                return .none

            case .createProject(.presented(.delegate(.projectCreated(let project)))):
                state.availableProjects.append(project)
                return .none

            case .createProject:
                return .none

            // MARK: Delegate

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$createProject, action: \.createProject) {
            CreateProjectFeature()
        }
    }

    // MARK: - Helpers

    private func handleSave(state: inout State) -> Effect<Action> {
        switch state.meta.toCreateSecretPayload(
            secretType: state.secretType,
            subType: state.selectedSubType
        ) {
        case .success(let payload):
            state.isSaving = true
            state.validationErrors = [:]
            let draft = state.meta.toSecretDraft(
                secretType: state.secretType,
                subType: state.selectedSubType
            )
            Log.info(
                """
                [CreateSecret] Save 요청 준비 완료
                  secretType    = \(state.secretType)
                  subType       = \(String(describing: state.selectedSubType))
                  draft         = \(draft)
                  payload       = \(payload)
                  projectIds    = \(state.meta.projectIds)
                """,
                category: .ui
            )
            return .run { [projectIds = state.meta.projectIds] send in
                do {
                    let secret = try await secretManagementClient.createSecret(
                        draft: draft,
                        payload: payload,
                        projectIds: projectIds
                    )
                    await send(.saveResponse(.success(secret)))
                } catch {
                    let mapped = (error as? SecretUseCaseError) ?? .unexpected
                    await send(.saveResponse(.failure(mapped)))
                }
            }

        case .failure(.missingRequired(let fieldIDs)):
            Log.warn("[CreateSecret] 필수 필드 누락: \(fieldIDs)", category: .ui)
            for fieldID in fieldIDs {
                state.validationErrors[fieldID] = .module("Required")
            }
            return .none

        case .failure(.invalidTypeCombination):
            Log.error("[CreateSecret] invalid (secretType, subType) 조합", category: .ui)
            return .none
        }
    }
}

// MARK: - AlertState presets

extension AlertState where Action == CreateSecretFeature.Action.Alert {
    static var confirmCancel: Self {
        Self {
            TextState("Discard changes?", bundle: .module)
        } actions: {
            ButtonState(role: .destructive, action: .confirmCancel) {
                TextState("Discard", bundle: .module)
            }
            ButtonState(role: .cancel) {
                TextState("Keep editing", bundle: .module)
            }
        }
    }

    /// 프로젝트 로드 실패 시 노출. 껍데기 — 재시도/오프라인 배지 등은 후속 작업에서 대체.
    static var projectLoadFailed: Self {
        Self {
            TextState("Failed to load projects", bundle: .module)
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK", bundle: .module)
            }
        } message: {
            TextState("The project list couldn't be loaded. Please try again later.", bundle: .module)
        }
    }
}
