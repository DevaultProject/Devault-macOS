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

    // MARK: - meta.isValid matrix

    @Test("meta.isValid: apiKeyToken 3개 서브타입 모두 name + value 요구")
    func metaIsValid_apiKeyToken() {
        for subType in [CreatableSecretSubType.apiKey, .accessToken, .webhookSecret] {
            var state = CreateSecretFeature.State(secretType: .apiKeyToken)
            state.selectedSubType = subType
            #expect(state.meta.isValid(for: .apiKeyToken, subType: subType) == false, "\(subType): 초기값 무효")
            state.meta.name = "n"
            #expect(state.meta.isValid(for: .apiKeyToken, subType: subType) == false, "\(subType): value 없어서 무효")
            state.meta.content = .apiKeyToken(APIKeyTokenFields(value: "v"))
            #expect(state.meta.isValid(for: .apiKeyToken, subType: subType) == true, "\(subType): 필수 필드 충족")
        }
    }

    @Test("meta.isValid: oauthClient는 clientId + clientSecret 모두 요구")
    func metaIsValid_oauthClient() {
        var state = CreateSecretFeature.State(secretType: .oauth)
        state.meta.name = "n"
        #expect(state.meta.isValid(for: .oauth, subType: .oauthClient) == false)
        state.meta.content = .oauthClient(OAuthClientFields(clientId: "id"))
        #expect(state.meta.isValid(for: .oauth, subType: .oauthClient) == false)
        state.meta.content = .oauthClient(OAuthClientFields(clientId: "id", clientSecret: "sec"))
        #expect(state.meta.isValid(for: .oauth, subType: .oauthClient) == true)
    }

    @Test("meta.isValid: serviceAccount는 credentialJSON 요구")
    func metaIsValid_serviceAccount() {
        var state = CreateSecretFeature.State(secretType: .oauth)
        state.selectedSubType = .serviceAccount
        state.meta.content = .serviceAccount(ServiceAccountFields())
        state.meta.name = "n"
        #expect(state.meta.isValid(for: .oauth, subType: .serviceAccount) == false)
        state.meta.content = .serviceAccount(ServiceAccountFields(credentialJSON: "{}"))
        #expect(state.meta.isValid(for: .oauth, subType: .serviceAccount) == true)
    }

    @Test("meta.isValid: database는 linkString 요구")
    func metaIsValid_database() {
        var state = CreateSecretFeature.State(secretType: .database)
        state.meta.name = "n"
        #expect(state.meta.isValid(for: .database, subType: nil) == false)
        state.meta.content = .database(DatabaseFields(linkString: "postgres://..."))
        #expect(state.meta.isValid(for: .database, subType: nil) == true)
    }

    @Test("meta.isValid: sshKey는 privateKey 요구")
    func metaIsValid_sshKey() {
        var state = CreateSecretFeature.State(secretType: .sshAndCredentials)
        state.meta.name = "n"
        #expect(state.meta.isValid(for: .sshAndCredentials, subType: .sshKey) == false)
        state.meta.content = .sshKey(SSHKeyFields(privateKey: "pk"))
        #expect(state.meta.isValid(for: .sshAndCredentials, subType: .sshKey) == true)
    }

    @Test("meta.isValid: sslTlsCertificate는 certificate + sslPrivateKey 모두 요구")
    func metaIsValid_sslTlsCertificate() {
        var state = CreateSecretFeature.State(secretType: .sshAndCredentials)
        state.selectedSubType = .sslTlsCertificate
        state.meta.content = .sslTlsCertificate(SSLCertFields())
        state.meta.name = "n"
        #expect(state.meta.isValid(for: .sshAndCredentials, subType: .sslTlsCertificate) == false)
        state.meta.content = .sslTlsCertificate(SSLCertFields(certificate: "c"))
        #expect(state.meta.isValid(for: .sshAndCredentials, subType: .sslTlsCertificate) == false)
        state.meta.content = .sslTlsCertificate(SSLCertFields(certificate: "c", sslPrivateKey: "pk"))
        #expect(state.meta.isValid(for: .sshAndCredentials, subType: .sslTlsCertificate) == true)
    }

    @Test("meta.isValid: environmentVariableSet는 envContent 요구")
    func metaIsValid_envSet() {
        var state = CreateSecretFeature.State(secretType: .environmentVariableSet)
        state.meta.name = "n"
        #expect(state.meta.isValid(for: .environmentVariableSet, subType: nil) == false)
        state.meta.content = .envSet(EnvSetFields(envContent: "FOO=bar"))
        #expect(state.meta.isValid(for: .environmentVariableSet, subType: nil) == true)
    }

    @Test("meta.isValid: licenseKey는 licenseKey 필드 요구")
    func metaIsValid_licenseKey() {
        var state = CreateSecretFeature.State(secretType: .etc)
        state.meta.name = "n"
        #expect(state.meta.isValid(for: .etc, subType: .licenseKey) == false)
        state.meta.content = .licenseKey(LicenseKeyFields(licenseKey: "lk"))
        #expect(state.meta.isValid(for: .etc, subType: .licenseKey) == true)
    }

    @Test("meta.isValid: custom은 value 요구")
    func metaIsValid_custom() {
        var state = CreateSecretFeature.State(secretType: .etc)
        state.selectedSubType = .custom
        state.meta.content = .custom(CustomFields())
        state.meta.name = "n"
        #expect(state.meta.isValid(for: .etc, subType: .custom) == false)
        state.meta.content = .custom(CustomFields(value: "v"))
        #expect(state.meta.isValid(for: .etc, subType: .custom) == true)
    }
}
