// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("SecretListFeature")
struct SecretListFeatureTests {

    @Test("task는 조회 시작 시 loading 상태로, 성공하면 loaded로 바뀐다")
    func taskSuccess() async {
        let secret = makeSecret(name: "GitHub API Key")
        let store = TestStore(initialState: SecretListFeature.State()) {
            SecretListFeature()
        } withDependencies: {
            $0.secretClient.fetchByQuery = { _ in [secret] }
        }

        await store.send(.task) {
            $0.secretsState = .loading
        }
        await store.receive(.secretsResponse(.success([secret]))) {
            $0.secretsState = .loaded([secret])
        }
    }

    @Test("task는 조회에 실패하면 failed 상태로 에러를 보존한다")
    func taskFailure() async {
        let store = TestStore(initialState: SecretListFeature.State()) {
            SecretListFeature()
        } withDependencies: {
            $0.secretClient.fetchByQuery = { _ in throw SecretUseCaseError.unexpected }
        }

        await store.send(.task) {
            $0.secretsState = .loading
        }
        await store.receive(.secretsResponse(.failure(.unexpected))) {
            $0.secretsState = .failed(.unexpected)
        }
    }

    @Test("didTapRetry는 failed 상태에서 다시 loading으로 전환하고 재조회한다")
    func retryRefetchesAfterFailure() async {
        let secret = makeSecret(name: "GitHub API Key")
        var initialState = SecretListFeature.State()
        initialState.secretsState = .failed(.unexpected)
        let store = TestStore(initialState: initialState) {
            SecretListFeature()
        } withDependencies: {
            $0.secretClient.fetchByQuery = { _ in [secret] }
        }

        await store.send(.didTapRetry) {
            $0.secretsState = .loading
        }
        await store.receive(.secretsResponse(.success([secret]))) {
            $0.secretsState = .loaded([secret])
        }
    }

    @Test("task는 State의 collection이 반영된 query로 조회한다")
    func taskUsesCollectionInQuery() async {
        let secret = makeSecret(name: "Database Password")
        let store = TestStore(initialState: SecretListFeature.State(collection: .deleted)) {
            SecretListFeature()
        } withDependencies: {
            $0.secretClient.fetchByQuery = { query in
                query.collection == .deleted ? [secret] : []
            }
        }

        await store.send(.task) {
            $0.secretsState = .loading
        }
        await store.receive(.secretsResponse(.success([secret]))) {
            $0.secretsState = .loaded([secret])
        }
    }

    @Test("didChangeSearchText는 300ms 디바운스 후 재조회한다")
    func searchDebounces() async {
        let clock = TestClock()
        let secret = makeSecret(name: "GitHub API Key")
        let store = TestStore(initialState: SecretListFeature.State()) {
            SecretListFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.secretClient.fetchByQuery = { query in
                query.searchText == "git" ? [secret] : []
            }
        }

        await store.send(.didChangeSearchText("git")) {
            $0.searchText = "git"
        }
        await clock.advance(by: .milliseconds(300))
        await store.receive(.secretsResponse(.success([secret]))) {
            $0.secretsState = .loaded([secret])
        }
    }

    @Test("didSelectSort는 디바운스 없이 즉시 재조회한다")
    func sortRefetchesImmediately() async {
        let secret = makeSecret(name: "GitHub API Key")
        let store = TestStore(initialState: SecretListFeature.State()) {
            SecretListFeature()
        } withDependencies: {
            $0.secretClient.fetchByQuery = { query in
                query.sort == .nameAscending ? [secret] : []
            }
        }

        await store.send(.didSelectSort(.nameAscending)) {
            $0.sort = .nameAscending
        }
        await store.receive(.secretsResponse(.success([secret]))) {
            $0.secretsState = .loaded([secret])
        }
    }

    @Test("초기 State는 idle이며, 조회 후 결과가 0개인 loaded([])와 구분된다")
    func initialStateIsIdleNotLoaded() {
        let state = SecretListFeature.State()

        #expect(state.secretsState == .idle)
        #expect(state.secretsState != .loaded([]))
    }

    @Test("expired collection의 query는 referenceDate를 확장 창만큼 밀고 expiringSoon 정렬을 강제한다")
    func expiredQueryWidensWindow() {
        let today = Date(timeIntervalSince1970: 0)
        let state = SecretListFeature.State(collection: .expired(referenceDate: today))

        let query = state.query

        guard case let .expired(windowEnd) = query.collection else {
            Issue.record("collection이 .expired가 아님")
            return
        }
        let expectedWindowEnd = today.addingTimeInterval(
            TimeInterval(SecretQuery.Collection.expiringSoonWindowDays) * 86_400
        )
        #expect(windowEnd == expectedWindowEnd)
        #expect(query.sort == .expiringSoon)
    }

    @Test("didSelectSecret은 selectedSecretID를 갱신하고 delegate로 알린다")
    func selectSecretNotifiesDelegate() async {
        let store = TestStore(initialState: SecretListFeature.State()) {
            SecretListFeature()
        }

        let id = UUID()
        await store.send(.didSelectSecret(id: id)) {
            $0.selectedSecretID = id
        }
        await store.receive(.delegate(.secretSelected(id)))
    }

    @Test("didTapDelete는 softDelete를 호출하고 성공하면 목록을 재조회한다")
    func deleteRefetchesOnSuccess() async {
        let secret = makeSecret(name: "GitHub API Key")
        let store = TestStore(initialState: SecretListFeature.State()) {
            SecretListFeature()
        } withDependencies: {
            $0.secretClient.softDelete = { _ in secret }
            $0.secretClient.fetchByQuery = { _ in [] }
        }

        await store.send(.didTapDelete(id: secret.id))
        await store.receive(.mutationResponse(.success(secret.id)))
        await store.receive(.delegate(.secretsChanged))
        await store.receive(.secretsResponse(.success([]))) {
            $0.secretsState = .loaded([])
        }
    }

    @Test("didTapDelete는 softDelete가 실패하면 alert를 띄우고 재조회하지 않는다")
    func deleteShowsAlertOnFailure() async {
        let secretID = UUID()
        let store = TestStore(initialState: SecretListFeature.State()) {
            SecretListFeature()
        } withDependencies: {
            $0.secretClient.softDelete = { _ in throw SecretUseCaseError.unexpected }
        }

        await store.send(.didTapDelete(id: secretID))
        await store.receive(.mutationResponse(.failure(.unexpected))) {
            $0.alert = AlertState {
                TextState("작업을 완료하지 못했어요")
            } actions: {
                ButtonState(role: .cancel) { TextState("확인") }
            } message: {
                TextState("잠시 후 다시 시도해주세요.")
            }
        }
    }

    @Test("didTapRecover는 restore를 호출하고 성공하면 목록을 재조회한다")
    func recoverRefetchesOnSuccess() async {
        let secret = makeSecret(name: "GitHub API Key")
        let store = TestStore(initialState: SecretListFeature.State(collection: .deleted)) {
            SecretListFeature()
        } withDependencies: {
            $0.secretClient.restore = { _ in secret }
            $0.secretClient.fetchByQuery = { _ in [] }
        }

        await store.send(.didTapRecover(id: secret.id))
        await store.receive(.mutationResponse(.success(secret.id)))
        await store.receive(.delegate(.secretsChanged))
        await store.receive(.secretsResponse(.success([]))) {
            $0.secretsState = .loaded([])
        }
    }

    @Test("didTapDeleteForever는 permanentlyDelete를 호출하고 성공하면 목록을 재조회한다")
    func deleteForeverRefetchesOnSuccess() async {
        let secretID = UUID()
        let store = TestStore(initialState: SecretListFeature.State(collection: .deleted)) {
            SecretListFeature()
        } withDependencies: {
            $0.secretClient.permanentlyDelete = { _ in }
            $0.secretClient.fetchByQuery = { _ in [] }
        }

        await store.send(.didTapDeleteForever(id: secretID))
        await store.receive(.mutationResponse(.success(secretID)))
        await store.receive(.delegate(.secretsChanged))
        await store.receive(.secretsResponse(.success([]))) {
            $0.secretsState = .loaded([])
        }
    }

    @Test("didTapAddToProject는 destination을 연다")
    func addToProjectPresentsDestination() async {
        let secretID = UUID()
        let store = TestStore(initialState: SecretListFeature.State()) {
            SecretListFeature()
        }

        await store.send(.didTapAddToProject(id: secretID)) {
            $0.destination = .addToProject(AddToProjectFeature.State(secretID: secretID))
        }
    }

    // MARK: - Helpers

    private func makeSecret(name: String) -> Secret {
        Secret(
            id: UUID(),
            name: name,
            secretType: .apiKeyToken,
            createdAt: .now,
            updatedAt: .now,
            payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
        )
    }
}
