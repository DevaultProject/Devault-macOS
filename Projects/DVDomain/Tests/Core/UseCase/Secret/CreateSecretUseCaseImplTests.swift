// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("CreateSecretUseCaseImpl")
struct CreateSecretUseCaseImplTests {
    // MARK: - execute(draft:payload:projectIDs:)

    @Test("정상 draft를 넣으면 이름이 정규화되고 주입한 id/date로 저장된다")
    func executeHappyPath() async throws {
        let repo = InMemorySecretRepository()
        let crypto = FakeSecretCryptoService()
        let fixedID = UUID(uuidString: "00000000-0000-0000-0000-0000000000FF")!
        let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)
        let sut = CreateSecretUseCaseImpl(
            repository: repo,
            cryptoService: crypto,
            idGenerator: { fixedID },
            dateProvider: { fixedDate }
        )

        let secret = try await sut.execute(
            draft: SecretFixture.draft(name: "  My API  "),
            payload: APIKeyPayload(value: "sk_test_123"),
            projectIDs: []
        )

        #expect(secret.id == fixedID)
        #expect(secret.name == "My API")
        #expect(secret.createdAt == fixedDate)
        #expect(secret.updatedAt == fixedDate)
        #expect(crypto.encryptCount == 1)
        #expect(repo.createCount == 1)
    }

    @Test("빈 이름의 draft는 invalidName 에러를 던진다")
    func executeRejectsEmptyName() async {
        let sut = CreateSecretUseCaseImpl(
            repository: InMemorySecretRepository(),
            cryptoService: FakeSecretCryptoService()
        )
        await #expect(throws: SecretUseCaseError.invalidName) {
            _ = try await sut.execute(
                draft: SecretFixture.draft(name: ""),
                payload: APIKeyPayload(value: "sk"),
                projectIDs: []
            )
        }
    }

    @Test("공백만 있는 이름의 draft는 invalidName 에러를 던진다")
    func executeRejectsWhitespaceName() async {
        let sut = CreateSecretUseCaseImpl(
            repository: InMemorySecretRepository(),
            cryptoService: FakeSecretCryptoService()
        )
        await #expect(throws: SecretUseCaseError.invalidName) {
            _ = try await sut.execute(
                draft: SecretFixture.draft(name: "   "),
                payload: APIKeyPayload(value: "sk"),
                projectIDs: []
            )
        }
    }

    @Test("암호화 실패는 cryptoFailure로 매핑되고 Repository는 호출되지 않는다")
    func executeMapsEncryptionFailure() async {
        let repo = InMemorySecretRepository()
        let crypto = FakeSecretCryptoService()
        crypto.errorOnEncryptPayload = .encryptionFailed
        let sut = CreateSecretUseCaseImpl(repository: repo, cryptoService: crypto)

        await #expect(throws: SecretUseCaseError.cryptoFailure(.encryptionFailed)) {
            _ = try await sut.execute(
                draft: SecretFixture.draft(),
                payload: APIKeyPayload(value: "sk"),
                projectIDs: []
            )
        }
        #expect(repo.createCount == 0)
    }

    @Test("Repository.create 실패는 repositoryFailure로 매핑된다")
    func executeMapsRepositoryFailure() async throws {
        let existingID = UUID()
        let repo = InMemorySecretRepository()
        repo.seed(SecretFixture.make(id: existingID))
        let sut = CreateSecretUseCaseImpl(
            repository: repo,
            cryptoService: FakeSecretCryptoService(),
            idGenerator: { existingID },
            dateProvider: { Date() }
        )

        await #expect(throws: SecretUseCaseError.repositoryFailure(.duplicateID(id: existingID))) {
            _ = try await sut.execute(
                draft: SecretFixture.draft(),
                payload: APIKeyPayload(value: "sk"),
                projectIDs: []
            )
        }
    }

    // MARK: - execute(draft:payload:metadata:projectIDs:)

    @Test("metadata 오버로드는 payload 암호화 후 metadata 인코딩까지 수행한다")
    func executeWithMetadataHappyPath() async throws {
        let repo = InMemorySecretRepository()
        let crypto = FakeSecretCryptoService()
        let sut = CreateSecretUseCaseImpl(repository: repo, cryptoService: crypto)

        let secret = try await sut.execute(
            draft: SecretFixture.draft(),
            payload: APIKeyPayload(value: "sk"),
            metadata: APIKeyMetadata(scope: "read"),
            projectIDs: []
        )

        #expect(crypto.encryptCount == 1)
        #expect(crypto.encodeCount == 1)
        #expect(secret.metadata != nil)
    }

    @Test("metadata 인코딩 실패는 cryptoFailure로 매핑되고 Repository는 호출되지 않는다")
    func executeWithMetadataMapsEncodeFailure() async {
        let repo = InMemorySecretRepository()
        let crypto = FakeSecretCryptoService()
        crypto.errorOnEncodeMetadata = .encodingFailed
        let sut = CreateSecretUseCaseImpl(repository: repo, cryptoService: crypto)

        await #expect(throws: SecretUseCaseError.cryptoFailure(.encodingFailed)) {
            _ = try await sut.execute(
                draft: SecretFixture.draft(),
                payload: APIKeyPayload(value: "sk"),
                metadata: APIKeyMetadata(scope: "read"),
                projectIDs: []
            )
        }
        #expect(repo.createCount == 0)
    }
}
