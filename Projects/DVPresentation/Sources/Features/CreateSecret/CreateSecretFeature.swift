// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
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
        var detectedServices: [SecretMetaFields.FieldID: String] = [:]

        /// 감지 엔진이 넘겨준 service chip 후보 목록. `ServicesFieldView`가 chip으로 표시.
        var serviceCandidates: [String] = []

        var isSaving = false

        @Presents var alert: AlertState<Action.Alert>?

        init(secretType: CreatableSecretType) {
            let initialSubType = secretType.availableSubTypes.first
            self.secretType = secretType
            self.selectedSubType = initialSubType
            self.meta = SecretMetaFields(
                content: .default(for: secretType, subType: initialSubType)
            )
        }

        /// Create 버튼의 disable/enable 판정.
        var isSaveEnabled: Bool {
            meta.isValid(for: secretType, subType: selectedSubType) && !isSaving
        }
    }

    // MARK: - Action

    enum Action: BindableAction, Equatable {

        // MARK: - View

        case task
        case binding(BindingAction<State>)
        case didTapCancel
        case didTapSave

        // MARK: - Internal

        case projectsResponse(Result<[Project], ProjectUseCaseError>)
        case saveResponse(Result<Secret, SecretUseCaseError>)
        /// 감지 엔진이 후보 서비스를 넘겨주면 `state.serviceCandidates`에 저장.
        case didDetectServiceCandidates([String])

        // MARK: - Child

        case alert(PresentationAction<Alert>)

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

            // MARK: Internal

            case .projectsResponse(.success(let projects)):
                state.availableProjects = projects
                return .none

            case .projectsResponse(.failure):
                state.availableProjects = []
                return .none

            case .saveResponse(.success(let secret)):
                state.isSaving = false
                return .send(.delegate(.secretCreated(secret.id)))

            case .saveResponse(.failure):
                state.isSaving = false
                return .none

            case .didDetectServiceCandidates(let candidates):
                state.serviceCandidates = candidates
                return .none

            // MARK: Child

            case .alert(.presented(.confirmCancel)):
                return .send(.delegate(.cancelled))

            case .alert:
                return .none

            // MARK: Delegate

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
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

        case .failure(.missingRequired(let fieldID)):
            state.validationErrors[fieldID] = "Required"
            return .none

        case .failure(.invalidTypeCombination):
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
}
