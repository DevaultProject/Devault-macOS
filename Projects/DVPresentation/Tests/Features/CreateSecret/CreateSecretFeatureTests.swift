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

    @Test("task 실패: availableProjects는 빈 배열 유지")
    func task_failure() async {
        let store = TestStore(initialState: .init(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        } withDependencies: {
            $0.projectClient.fetchProjects = {
                throw ProjectUseCaseError.unexpected
            }
        }

        await store.send(.task)
        await store.receive(.projectsResponse(.failure(.unexpected)))
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

    @Test("didTapSave 매핑 실패: name이 비어 있으면 validationErrors[.name] 세팅, Effect 미발행")
    func didTapSave_missingName() async {
        let store = TestStore(initialState: .init(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        }

        await store.send(.didTapSave) {
            $0.validationErrors = [.name: "Required"]
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

    // MARK: - didTapServiceChip

    @Test("didTapServiceChip: chip 내용이 servicesInput으로 옮겨지고 service는 clear")
    func didTapServiceChip() async {
        var initialState = CreateSecretFeature.State(secretType: .apiKeyToken)
        initialState.meta.service = "github"

        let store = TestStore(initialState: initialState) {
            CreateSecretFeature()
        }

        await store.send(.didTapServiceChip("github")) {
            $0.meta.servicesInput = "github"
            $0.meta.service = ""
        }
    }

    // MARK: - isSaveEnabled matrix

    @Test("isSaveEnabled: apiKeyToken 3개 서브타입 모두 name + value 요구")
    func isSaveEnabled_apiKeyToken() {
        for subType in [CreatableSecretSubType.apiKey, .accessToken, .webhookSecret] {
            var state = CreateSecretFeature.State(secretType: .apiKeyToken)
            state.selectedSubType = subType
            #expect(state.isSaveEnabled == false, "\(subType): 초기값 비활성")
            state.meta.name = "n"
            #expect(state.isSaveEnabled == false, "\(subType): value 없어서 비활성")
            state.meta.content = .apiKeyToken(APIKeyTokenFields(value: "v"))
            #expect(state.isSaveEnabled == true, "\(subType): 필수 필드 충족")
            state.isSaving = true
            #expect(state.isSaveEnabled == false, "\(subType): 저장 중일 땐 비활성")
        }
    }

    @Test("isSaveEnabled: oauthClient는 clientId + clientSecret 모두 요구")
    func isSaveEnabled_oauthClient() {
        var state = CreateSecretFeature.State(secretType: .oauth)
        state.meta.name = "n"
        #expect(state.isSaveEnabled == false)
        state.meta.content = .oauthClient(OAuthClientFields(clientId: "id"))
        #expect(state.isSaveEnabled == false)
        state.meta.content = .oauthClient(OAuthClientFields(clientId: "id", clientSecret: "sec"))
        #expect(state.isSaveEnabled == true)
    }

    @Test("isSaveEnabled: serviceAccount는 credentialJSON 요구")
    func isSaveEnabled_serviceAccount() {
        var state = CreateSecretFeature.State(secretType: .oauth)
        state.selectedSubType = .serviceAccount
        state.meta.content = .serviceAccount(ServiceAccountFields())
        state.meta.name = "n"
        #expect(state.isSaveEnabled == false)
        state.meta.content = .serviceAccount(ServiceAccountFields(credentialJSON: "{}"))
        #expect(state.isSaveEnabled == true)
    }

    @Test("isSaveEnabled: database는 linkString 요구")
    func isSaveEnabled_database() {
        var state = CreateSecretFeature.State(secretType: .database)
        state.meta.name = "n"
        #expect(state.isSaveEnabled == false)
        state.meta.content = .database(DatabaseFields(linkString: "postgres://..."))
        #expect(state.isSaveEnabled == true)
    }

    @Test("isSaveEnabled: sshKey는 privateKey 요구")
    func isSaveEnabled_sshKey() {
        var state = CreateSecretFeature.State(secretType: .sshAndCredentials)
        state.meta.name = "n"
        #expect(state.isSaveEnabled == false)
        state.meta.content = .sshKey(SSHKeyFields(privateKey: "pk"))
        #expect(state.isSaveEnabled == true)
    }

    @Test("isSaveEnabled: sslTlsCertificate는 certificate + sslPrivateKey 모두 요구")
    func isSaveEnabled_sslTlsCertificate() {
        var state = CreateSecretFeature.State(secretType: .sshAndCredentials)
        state.selectedSubType = .sslTlsCertificate
        state.meta.content = .sslTlsCertificate(SSLCertFields())
        state.meta.name = "n"
        #expect(state.isSaveEnabled == false)
        state.meta.content = .sslTlsCertificate(SSLCertFields(certificate: "c"))
        #expect(state.isSaveEnabled == false)
        state.meta.content = .sslTlsCertificate(SSLCertFields(certificate: "c", sslPrivateKey: "pk"))
        #expect(state.isSaveEnabled == true)
    }

    @Test("isSaveEnabled: environmentVariableSet는 envContent 요구")
    func isSaveEnabled_envSet() {
        var state = CreateSecretFeature.State(secretType: .environmentVariableSet)
        state.meta.name = "n"
        #expect(state.isSaveEnabled == false)
        state.meta.content = .envSet(EnvSetFields(envContent: "FOO=bar"))
        #expect(state.isSaveEnabled == true)
    }

    @Test("isSaveEnabled: licenseKey는 licenseKey 필드 요구")
    func isSaveEnabled_licenseKey() {
        var state = CreateSecretFeature.State(secretType: .etc)
        state.meta.name = "n"
        #expect(state.isSaveEnabled == false)
        state.meta.content = .licenseKey(LicenseKeyFields(licenseKey: "lk"))
        #expect(state.isSaveEnabled == true)
    }

    @Test("isSaveEnabled: custom은 value 요구")
    func isSaveEnabled_custom() {
        var state = CreateSecretFeature.State(secretType: .etc)
        state.selectedSubType = .custom
        state.meta.content = .custom(CustomFields())
        state.meta.name = "n"
        #expect(state.isSaveEnabled == false)
        state.meta.content = .custom(CustomFields(value: "v"))
        #expect(state.isSaveEnabled == true)
    }
}
