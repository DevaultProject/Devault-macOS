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
