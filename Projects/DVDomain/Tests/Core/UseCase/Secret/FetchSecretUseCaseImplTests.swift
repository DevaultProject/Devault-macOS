// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("FetchSecretUseCaseImpl")
struct FetchSecretUseCaseImplTests {
    // MARK: - fetch(id:)

    @Test("fetch(id:)는 Repository 결과를 그대로 반환한다")
    func fetchByIDReturnsRepositoryResult() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let sut = makeSUT(repository: repo)

        let result = try await sut.fetch(id: secret.id)

        #expect(result == secret)
    }

    @Test("fetch(id:)는 Repository가 nil을 주면 nil을 반환한다")
    func fetchByIDReturnsNil() async throws {
        let sut = makeSUT(repository: InMemorySecretRepository())

        let result = try await sut.fetch(id: UUID())

        #expect(result == nil)
    }

    // MARK: - fetch(query:)

    @Test("fetch(query:)는 Repository 결과를 그대로 반환한다")
    func fetchQueryReturnsRepositoryResult() async throws {
        let repo = InMemorySecretRepository()
        repo.seed(SecretFixture.make(id: UUID()))
        repo.seed(SecretFixture.make(id: UUID()))
        let sut = makeSUT(repository: repo)

        let result = try await sut.fetch(query: SecretQuery())

        #expect(result.count == 2)
    }

    // MARK: - count(query:)

    @Test("count(query:)는 collection 조건에 맞는 개수만 센다")
    func countAppliesCollection() async throws {
        let repo = InMemorySecretRepository()
        repo.seed(SecretFixture.make(id: UUID()))
        repo.seed(SecretFixture.make(id: UUID(), liked: true))
        repo.seed(SecretFixture.make(id: UUID(), deletedAt: .now))
        let sut = makeSUT(repository: repo)

        #expect(try await sut.count(query: SecretQuery(collection: .all)) == 2)
        #expect(try await sut.count(query: SecretQuery(collection: .liked)) == 1)
        #expect(try await sut.count(query: SecretQuery(collection: .deleted)) == 1)
    }

    @Test("count(query:)는 secretType·service·environment 필터를 함께 적용한다")
    func countAppliesFieldFilters() async throws {
        let repo = InMemorySecretRepository()
        repo.seed(SecretFixture.make(id: UUID(), service: "github", environment: "prod"))
        repo.seed(SecretFixture.make(id: UUID(), service: "github", environment: "dev"))
        repo.seed(SecretFixture.make(id: UUID(), secretType: .database, service: "aws"))
        let sut = makeSUT(repository: repo)

        #expect(try await sut.count(query: SecretQuery(service: "github")) == 2)
        #expect(try await sut.count(query: SecretQuery(service: "github", environment: "prod")) == 1)
        #expect(try await sut.count(query: SecretQuery(secretType: .database)) == 1)
    }

    @Test("count(query:)는 만료된 Secret을 .all에서 제외하고 .expired에서만 센다")
    func countSeparatesExpired() async throws {
        let repo = InMemorySecretRepository()
        let now = Date.now
        repo.seed(SecretFixture.make(id: UUID(), expiresAt: now.addingTimeInterval(3600)))
        repo.seed(SecretFixture.make(id: UUID(), expiresAt: now.addingTimeInterval(-3600)))
        repo.seed(SecretFixture.make(id: UUID(), expiresAt: nil))
        let sut = makeSUT(repository: repo)

        // 만료일이 없는 Secret은 "만료되지 않음"으로 취급되어 .all에 포함된다.
        #expect(try await sut.count(query: SecretQuery(collection: .all)) == 2)
        #expect(try await sut.count(query: SecretQuery(collection: .expired(referenceDate: now))) == 1)
    }

    @Test("count(query:)는 Repository 에러를 SecretUseCaseError로 매핑한다")
    func countMapsRepositoryError() async {
        let repo = InMemorySecretRepository()
        repo.errorOnCountQuery = .persistenceFailed
        let sut = makeSUT(repository: repo)

        await #expect(throws: SecretUseCaseError.repositoryFailure(.persistenceFailed)) {
            _ = try await sut.count(query: SecretQuery())
        }
    }

    // MARK: - revealPayload

    @Test("revealPayload는 인증 후 fetch·decrypt를 호출한다")
    func revealPayloadHappyPath() async throws {
        let repo = InMemorySecretRepository()
        let crypto = FakeSecretCryptoService()
        let auth = StubUserAuthenticationService()
        let payload = APIKeyPayload(value: "sk_reveal")
        let encoded = try JSONEncoder().encode(payload)
        let secret = SecretFixture.make(payload: SecretPayload(
            encryptedData: encoded,
            keyTag: crypto.keyTag,
            schemaVersion: APIKeyPayload.schemaVersion
        ))
        repo.seed(secret)
        let sut = FetchSecretUseCaseImpl(
            repository: repo,
            cryptoService: crypto,
            authenticationService: auth
        )

        let revealed: APIKeyPayload = try await sut.revealPayload(id: secret.id, as: APIKeyPayload.self)

        #expect(revealed == payload)
        #expect(auth.authenticateCount == 1)
        #expect(repo.fetchByIDCount == 1)
        #expect(crypto.decryptCount == 1)
    }

    @Test("인증 실패 시 fetch·decrypt는 호출되지 않고 authenticationFailure로 매핑된다")
    func revealPayloadAuthenticationFailed() async {
        let repo = InMemorySecretRepository()
        let crypto = FakeSecretCryptoService()
        let auth = StubUserAuthenticationService()
        auth.errorOnAuthenticate = .cancelled
        let sut = FetchSecretUseCaseImpl(
            repository: repo,
            cryptoService: crypto,
            authenticationService: auth
        )

        await #expect(throws: SecretUseCaseError.authenticationFailure(.cancelled)) {
            _ = try await sut.revealPayload(id: UUID(), as: APIKeyPayload.self)
        }
        #expect(repo.fetchByIDCount == 0)
        #expect(crypto.decryptCount == 0)
    }

    @Test("존재하지 않는 Secret은 secretNotFound로 매핑되고 decrypt는 호출되지 않는다")
    func revealPayloadSecretNotFound() async {
        let repo = InMemorySecretRepository()
        let crypto = FakeSecretCryptoService()
        let missingID = UUID()
        let sut = FetchSecretUseCaseImpl(
            repository: repo,
            cryptoService: crypto,
            authenticationService: StubUserAuthenticationService()
        )

        await #expect(throws: SecretUseCaseError.secretNotFound(id: missingID)) {
            _ = try await sut.revealPayload(id: missingID, as: APIKeyPayload.self)
        }
        #expect(crypto.decryptCount == 0)
    }

    @Test("복호화 실패는 cryptoFailure로 매핑된다")
    func revealPayloadDecryptionFailed() async {
        let repo = InMemorySecretRepository()
        let crypto = FakeSecretCryptoService()
        crypto.errorOnDecryptPayload = .decryptionFailed
        let secret = SecretFixture.make()
        repo.seed(secret)
        let sut = FetchSecretUseCaseImpl(
            repository: repo,
            cryptoService: crypto,
            authenticationService: StubUserAuthenticationService()
        )

        await #expect(throws: SecretUseCaseError.cryptoFailure(.decryptionFailed)) {
            _ = try await sut.revealPayload(id: secret.id, as: APIKeyPayload.self)
        }
    }

    // MARK: - Helpers

    private func makeSUT(repository: InMemorySecretRepository) -> FetchSecretUseCaseImpl {
        FetchSecretUseCaseImpl(
            repository: repository,
            cryptoService: FakeSecretCryptoService(),
            authenticationService: StubUserAuthenticationService()
        )
    }
}
