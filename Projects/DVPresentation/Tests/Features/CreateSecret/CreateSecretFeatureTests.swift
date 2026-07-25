// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation
import Testing

@testable import DVPresentation

@Suite("CreateSecretFeature")
@MainActor
struct CreateSecretFeatureTests {

    // MARK: - task

    @Test("task 성공: availableProjects가 로드된 목록으로 채워짐")
    func task_success() async {
        let projects = [
            Project(id: UUID(), name: "Backend",  createdAt: Date(), updatedAt: Date()),
            Project(id: UUID(), name: "Mobile",   createdAt: Date(), updatedAt: Date()),
        ]

        let store = TestStore(initialState: .init(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        } withDependencies: {
            $0.projectClient.fetchProjects = { projects }
        }

        await store.send(.task)
        await store.receive(.projectsResponse(.success(projects))) {
            $0.availableProjects = projects
        }
    }

    @Test("task 실패: availableProjects는 빈 배열 유지 + projectLoadFailed alert 노출")
    func task_failure() async {
        let store = TestStore(initialState: .init(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        } withDependencies: {
            $0.projectClient.fetchProjects = {
                throw ProjectUseCaseError.unexpected
            }
        }

        await store.send(.task)
        await store.receive(.projectsResponse(.failure(.unexpected))) {
            $0.alert = .projectLoadFailed
        }
    }

    // MARK: - selectedSubType binding

    @Test("selectedSubType 변경: content가 새 case로 교체되고 validationErrors 초기화")
    func binding_selectedSubType_swapsContentAndClearsErrors() async {
        var initialState = CreateSecretFeature.State(secretType: .oauth)
        initialState.validationErrors = [.name: "Required"]
        initialState.meta.content = .oauthClient(OAuthClientFields(clientId: "prev-id"))

        let store = TestStore(initialState: initialState) {
            CreateSecretFeature()
        }

        await store.send(.set(\.selectedSubType, .serviceAccount)) {
            $0.selectedSubType = .serviceAccount
            $0.meta.content = .default(for: .oauth, subType: .serviceAccount)
            $0.validationErrors = [:]
        }
    }

    // MARK: - didTapSave

    @Test("didTapSave 성공: isSaving true → response로 false → delegate(.secretCreated)")
    func didTapSave_success() async {
        var initialState = CreateSecretFeature.State(secretType: .apiKeyToken)
        initialState.meta.name = "MyKey"
        initialState.meta.content = .apiKeyToken(APIKeyTokenFields(value: "sk_test"))

        let createdId = UUID()
        let createdSecret = Secret(
            id: createdId,
            name: "MyKey",
            secretType: .apiKeyToken,
            subType: .apiKey,
            createdAt: Date(),
            updatedAt: Date(),
            payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
        )

        let store = TestStore(initialState: initialState) {
            CreateSecretFeature()
        } withDependencies: {
            $0.secretManagementClient.createSecret = { _, _, _ in createdSecret }
        }

        await store.send(.didTapSave) {
            $0.isSaving = true
        }
        await store.receive(.saveResponse(.success(createdSecret))) {
            $0.isSaving = false
        }
        await store.receive(.delegate(.secretCreated(createdId)))
    }

    @Test("didTapSave 매핑 실패: 초기 상태(name + value 모두 빈값) → 둘 다 warning, Effect 미발행")
    func didTapSave_missingName() async {
        let store = TestStore(initialState: .init(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        }

        await store.send(.didTapSave) {
            $0.validationErrors = [.name: "Required", .value: "Required"]
        }
        // Effect 미발행 — receive 없음
    }

    @Test("didTapSave 매핑 실패: name 있으나 필수 필드 누락 시 해당 필드 지목")
    func didTapSave_missingRequiredContent() async {
        var initialState = CreateSecretFeature.State(secretType: .apiKeyToken)
        initialState.meta.name = "n"
        // meta.content.apiKeyToken.value는 빈 문자열 (default)

        let store = TestStore(initialState: initialState) {
            CreateSecretFeature()
        }

        await store.send(.didTapSave) {
            $0.validationErrors = [.value: "Required"]
        }
    }

    @Test("didTapSave 재시도: 이전 validationErrors가 새 검증 결과로 대체됨 (해결된 필드 warning 사라짐)")
    func didTapSave_retryReplacesPriorErrors() async {
        var initialState = CreateSecretFeature.State(secretType: .apiKeyToken)
        // 이전 시도의 잔존: name/value 둘 다 warning
        initialState.validationErrors = [.name: "Required", .value: "Required"]
        // 사용자가 name만 채운 상태
        initialState.meta.name = "n"

        let store = TestStore(initialState: initialState) {
            CreateSecretFeature()
        }

        await store.send(.didTapSave) {
            // .name warning 사라지고 .value만 남아야 함 (이전 [.name]은 리셋됨)
            $0.validationErrors = [.value: "Required"]
        }
    }

    @Test("didTapSave 매핑 실패: name + type-specific 다중 누락 시 모두 세팅")
    func didTapSave_multipleMissing() async {
        // oauthClient는 clientId + clientSecret 둘 다 required — name까지 3개 모두 비면 3개 warning
        let store = TestStore(initialState: .init(secretType: .oauth)) {
            CreateSecretFeature()
        }

        await store.send(.didTapSave) {
            $0.validationErrors = [
                .name: "Required",
                .clientId: "Required",
                .clientSecret: "Required",
            ]
        }
    }

    // MARK: - didTapCancel

    @Test("didTapCancel: alert 노출 → confirmCancel → alert dismiss + delegate(.cancelled)")
    func didTapCancel_confirm() async {
        let store = TestStore(initialState: .init(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        }

        await store.send(.didTapCancel) {
            $0.alert = .confirmCancel
        }
        await store.send(.alert(.presented(.confirmCancel))) {
            $0.alert = nil
        }
        await store.receive(.delegate(.cancelled))
    }

    // MARK: - saveResponse.failure

    @Test("saveResponse(.failure): isSaving false로 해제")
    func saveResponse_failure() async {
        var initialState = CreateSecretFeature.State(secretType: .apiKeyToken)
        initialState.isSaving = true

        let store = TestStore(initialState: initialState) {
            CreateSecretFeature()
        }

        await store.send(.saveResponse(.failure(.unexpected))) {
            $0.isSaving = false
        }
        // TODO(#41-followup): 실패 alert 노출 시 여기서 alert state 검증 추가.
    }

    // MARK: - didTapCreateProject

    @Test("didTapCreateProject: createProject State가 세팅되어 sheet 노출")
    func didTapCreateProject_opensSheet() async {
        let store = TestStore(initialState: .init(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        }

        await store.send(.didTapCreateProject) {
            $0.createProject = CreateProjectFeature.State()
        }
    }

    @Test("createProject 델리게이트: 생성된 프로젝트가 availableProjects에 추가")
    func createProject_delegateProjectCreated_appendsToAvailable() async {
        var initialState = CreateSecretFeature.State(secretType: .apiKeyToken)
        initialState.createProject = CreateProjectFeature.State()

        let store = TestStore(initialState: initialState) {
            CreateSecretFeature()
        }

        let newProject = Project(
            id: UUID(),
            name: "New Project",
            createdAt: Date(),
            updatedAt: Date()
        )

        await store.send(.createProject(.presented(.delegate(.projectCreated(newProject))))) {
            $0.availableProjects.append(newProject)
        }
    }

    // MARK: - didDetectServiceCandidates

    @Test("didDetectServiceCandidates: 후보 목록이 state.serviceCandidates에 저장됨")
    func didDetectServiceCandidates() async {
        let store = TestStore(initialState: .init(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        }

        await store.send(.didDetectServiceCandidates(["github.com", "gitlab.com"])) {
            $0.serviceCandidates = ["github.com", "gitlab.com"]
        }
    }

    // MARK: - isSaveEnabled

    @Test("isSaveEnabled: 저장 중이 아니면 항상 true — 필수 필드 검증은 didTapSave에서 수행")
    func isSaveEnabled_onlyBlocksWhileSaving() {
        var state = CreateSecretFeature.State(secretType: .apiKeyToken)
        #expect(state.isSaveEnabled == true, "초기 상태(빈 필드)에도 활성 — 탭 시점에 인라인 warning 노출을 위함")
        state.isSaving = true
        #expect(state.isSaveEnabled == false, "저장 중엔 재클릭 차단")
    }

}
