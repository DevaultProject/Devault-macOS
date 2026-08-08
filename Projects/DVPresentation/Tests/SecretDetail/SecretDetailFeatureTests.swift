// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

import ComposableArchitecture
import DVDomain

@testable import DVPresentation

@Suite("SecretDetailFeature")
@MainActor
struct SecretDetailFeatureTests {

    // MARK: - Helpers

    private static func makeSecret(
        name: String = "Test Secret",
        secretType: SecretType = .apiKeyToken
    ) -> Secret {
        Secret(
            id: UUID(),
            name: name,
            secretType: secretType,
            createdAt: Date(),
            updatedAt: Date(),
            payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
        )
    }

    // MARK: - Viewing 진입

    @Test("초기 mode는 .viewing이다")
    func initialModeIsViewing() async {
        let secret = Self.makeSecret()
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        }

        store.assert { state in
            #expect(state.mode == .viewing)
            #expect(state.editFields == nil)
        }
    }

    @Test("task 성공: projects + payload 모두 로드됨")
    func task_success() async {
        let secret = Self.makeSecret()
        let projects = [
            Project(id: UUID(), name: "Backend", createdAt: Date(), updatedAt: Date()),
        ]
        let payload = CreateSecretPayload.apiKey(APIKeyPayload(value: "test_token"), nil)

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.projectClient.fetchProjects = { projects }
            $0.secretClient.revealPayload = { _ in payload }
        }

        await store.send(.task) {
            $0.isLoadingProjects = true
            $0.payloadState = .loading
        }
        // mock이 동기 반환이므로 .merge 선언 순서대로 수신됨 (projects → payload)
        await store.receive(.projectsResponse(.success(projects))) {
            $0.isLoadingProjects = false
            $0.availableProjects = projects
        }
        await store.receive(.payloadResponse(.success(payload))) {
            $0.payloadState = .loaded(payload)
        }
    }

    @Test("task payload 실패: payloadState .failed + alert 노출")
    func task_payloadFailure() async {
        let secret = Self.makeSecret()

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.projectClient.fetchProjects = { [] }
            $0.secretClient.revealPayload = { _ in throw SecretUseCaseError.cryptoFailure(.decryptionFailed) }
        }

        await store.send(.task) {
            $0.isLoadingProjects = true
            $0.payloadState = .loading
        }
        await store.receive(.projectsResponse(.success([]))) {
            $0.isLoadingProjects = false
        }
        await store.receive(.payloadResponse(.failure(.cryptoFailure(.decryptionFailed)))) {
            $0.payloadState = .failed(.cryptoFailure(.decryptionFailed))
            $0.alert = .payloadRevealFailed(.decryptionFailed)
        }
    }

    @Test("task payload 인증 실패: authRequired alert 노출")
    func task_payloadAuthFailure() async {
        let secret = Self.makeSecret()

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.projectClient.fetchProjects = { [] }
            $0.secretClient.revealPayload = { _ in throw SecretUseCaseError.authenticationFailure(.cancelled) }
        }

        await store.send(.task) {
            $0.isLoadingProjects = true
            $0.payloadState = .loading
        }
        await store.receive(.projectsResponse(.success([]))) {
            $0.isLoadingProjects = false
        }
        await store.receive(.payloadResponse(.failure(.authenticationFailure(.cancelled)))) {
            $0.payloadState = .failed(.authenticationFailure(.cancelled))
            $0.alert = .payloadRevealFailed(.authRequired)
        }
    }

    // MARK: - Close delegate

    @Test("didTapClose는 delegate(.closed)를 emit한다")
    func didTapClose_emitsClosedDelegate() async {
        let secret = Self.makeSecret()
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        }

        await store.send(.didTapClose)
        await store.receive(.delegate(.closed))
    }
}
