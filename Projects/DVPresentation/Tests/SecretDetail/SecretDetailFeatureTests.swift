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
        secretType: SecretType = .apiKeyToken,
        liked: Bool = false
    ) -> Secret {
        Secret(
            id: UUID(),
            name: name,
            secretType: secretType,
            liked: liked,
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

    // `task`는 세 effect를 `.merge`한다. TCA는 merge된 effect의 수신 순서를 보장하지 않으므로
    // 관심 없는 쪽 dependency를 `CancellationError`로 스텁한다 — reducer가 `catch is CancellationError`로
    // 아무 액션도 발행하지 않기 때문에 그 effect는 응답을 내지 않고, 수신 순서 의존이 사라진다.
    // 부수적으로 CancellationError 경로 자체도 검증된다.

    @Test("task: projects 로드 성공")
    func task_projectsSuccess() async {
        let secret = Self.makeSecret()
        let projects = [
            Project(id: UUID(), name: "Backend", createdAt: Date(), updatedAt: Date()),
        ]

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.projectClient.fetchProjects = { projects }
            $0.secretClient.revealPayload = { _ in throw CancellationError() }
            $0.secretClient.fetchLinkedProjects = { _ in throw CancellationError() }
        }

        await store.send(.task) {
            $0.isLoadingProjects = true
            $0.payloadState = .loading
        }
        await store.receive(.projectsResponse(.success(projects))) {
            $0.isLoadingProjects = false
            $0.availableProjects = projects
        }
    }

    @Test("task: payload 로드 성공")
    func task_payloadSuccess() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.apiKey(APIKeyPayload(value: "test_token"), nil)

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.projectClient.fetchProjects = { throw CancellationError() }
            $0.secretClient.fetchLinkedProjects = { _ in throw CancellationError() }
            $0.secretClient.revealPayload = { _ in payload }
        }

        await store.send(.task) {
            $0.isLoadingProjects = true
            $0.payloadState = .loading
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
            $0.projectClient.fetchProjects = { throw CancellationError() }
            $0.secretClient.fetchLinkedProjects = { _ in throw CancellationError() }
            $0.secretClient.revealPayload = { _ in throw SecretUseCaseError.cryptoFailure(.decryptionFailed) }
        }

        await store.send(.task) {
            $0.isLoadingProjects = true
            $0.payloadState = .loading
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
            $0.projectClient.fetchProjects = { throw CancellationError() }
            $0.secretClient.fetchLinkedProjects = { _ in throw CancellationError() }
            $0.secretClient.revealPayload = { _ in throw SecretUseCaseError.authenticationFailure(.cancelled) }
        }

        await store.send(.task) {
            $0.isLoadingProjects = true
            $0.payloadState = .loading
        }
        await store.receive(.payloadResponse(.failure(.authenticationFailure(.cancelled)))) {
            $0.payloadState = .failed(.authenticationFailure(.cancelled))
            $0.alert = .payloadRevealFailed(.authRequired)
        }
    }

    @Test("task: 연결된 프로젝트 로드 성공")
    func task_linkedProjectsSuccess() async {
        let secret = Self.makeSecret()
        let linked = [
            Project(id: UUID(), name: "Backend", createdAt: Date(), updatedAt: Date()),
        ]

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.projectClient.fetchProjects = { throw CancellationError() }
            $0.secretClient.revealPayload = { _ in throw CancellationError() }
            $0.secretClient.fetchLinkedProjects = { _ in linked }
        }

        await store.send(.task) {
            $0.isLoadingProjects = true
            $0.payloadState = .loading
        }
        await store.receive(.linkedProjectsResponse(.success(linked))) {
            $0.linkedProjects = linked
        }
    }

    @Test("연결된 프로젝트 조회 실패는 alert를 띄우지 않는다")
    func task_linkedProjectsFailure_noAlert() async {
        let secret = Self.makeSecret()

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.projectClient.fetchProjects = { throw CancellationError() }
            $0.secretClient.revealPayload = { _ in throw CancellationError() }
            $0.secretClient.fetchLinkedProjects = { _ in throw SecretUseCaseError.unexpected }
        }

        await store.send(.task) {
            $0.isLoadingProjects = true
            $0.payloadState = .loading
        }
        await store.receive(.linkedProjectsResponse(.failure(.unexpected)))
        #expect(store.state.alert == nil)
        #expect(store.state.linkedProjects.isEmpty)
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

    // MARK: - 즐겨찾기

    @Test("didTapToggleLike 성공: secret 교체 + secretUpdated delegate")
    func toggleLike_success() async {
        let secret = Self.makeSecret(liked: false)
        var updated = secret
        updated.liked = true

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.setLiked = { _, _ in updated }
        }

        await store.send(.didTapToggleLike)
        await store.receive(.likeResponse(.success(updated))) {
            $0.secret = updated
        }
        await store.receive(.delegate(.secretUpdated(updated)))
    }

    @Test("didTapToggleLike는 현재 liked의 반대값을 전달한다")
    func toggleLike_sendsInvertedValue() async {
        let secret = Self.makeSecret(liked: true)
        var updated = secret
        updated.liked = false

        let requestedLiked = LockIsolated<Bool?>(nil)
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.setLiked = { _, liked in
                requestedLiked.setValue(liked)
                return updated
            }
        }

        await store.send(.didTapToggleLike)
        await store.receive(.likeResponse(.success(updated))) {
            $0.secret = updated
        }
        await store.receive(.delegate(.secretUpdated(updated)))
        #expect(requestedLiked.value == false)
    }

    @Test("didTapToggleLike 실패: alert 노출 + secret 유지")
    func toggleLike_failure() async {
        let secret = Self.makeSecret(liked: false)
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.setLiked = { _, _ in throw SecretUseCaseError.unexpected }
        }

        await store.send(.didTapToggleLike)
        await store.receive(.likeResponse(.failure(.unexpected))) {
            $0.alert = .likeFailed
        }
        #expect(store.state.secret.liked == false)
    }

    // MARK: - 삭제

    @Test("didTapDelete는 즉시 삭제하지 않고 확인 alert를 띄운다")
    func didTapDelete_presentsConfirmAlert() async {
        let secret = Self.makeSecret()
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        }

        await store.send(.didTapDelete) {
            $0.alert = .confirmDelete
        }
    }

    @Test("confirmDelete 성공: deleted delegate emit")
    func confirmDelete_success() async {
        let secret = Self.makeSecret()
        var deleted = secret
        deleted.deletedAt = Date()

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.softDelete = { _ in deleted }
        }

        await store.send(.didTapDelete) {
            $0.alert = .confirmDelete
        }
        await store.send(.alert(.presented(.confirmDelete))) {
            $0.alert = nil
            $0.isDeleting = true
        }
        await store.receive(.deleteResponse(.success(deleted))) {
            $0.isDeleting = false
        }
        await store.receive(.delegate(.deleted(secret.id)))
    }

    @Test("confirmDelete 실패: isDeleting 해제 + alert 노출")
    func confirmDelete_failure() async {
        let secret = Self.makeSecret()
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.softDelete = { _ in throw SecretUseCaseError.unexpected }
        }

        await store.send(.didTapDelete) {
            $0.alert = .confirmDelete
        }
        await store.send(.alert(.presented(.confirmDelete))) {
            $0.alert = nil
            $0.isDeleting = true
        }
        await store.receive(.deleteResponse(.failure(.unexpected))) {
            $0.isDeleting = false
            $0.alert = .deleteFailed
        }
    }
}
