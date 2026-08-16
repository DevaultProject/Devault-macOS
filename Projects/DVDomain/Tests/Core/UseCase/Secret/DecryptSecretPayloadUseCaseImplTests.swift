// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("DecryptSecretPayloadUseCaseImpl")
struct DecryptSecretPayloadUseCaseImplTests {
    @Test("Secret을 조회해 payload를 복호화한다")
    func decryptPayloadReturnsDecodedPayload() async throws {
        let repository = InMemorySecretRepository()
        let cryptoService = FakeSecretCryptoService()
        let payload = APIKeyPayload(value: "sk_copy")
        let encoded = try JSONEncoder().encode(payload)
        let secret = SecretFixture.make(payload: SecretPayload(
            encryptedData: encoded,
            keyTag: cryptoService.keyTag,
            schemaVersion: APIKeyPayload.schemaVersion
        ))
        repository.seed(secret)
        let sut = DecryptSecretPayloadUseCaseImpl(
            repository: repository,
            cryptoService: cryptoService
        )

        let decrypted: APIKeyPayload = try await sut.decryptPayload(
            id: secret.id,
            as: APIKeyPayload.self
        )

        #expect(decrypted == payload)
        #expect(repository.fetchByIDCount == 1)
        #expect(cryptoService.decryptCount == 1)
    }

    @Test("존재하지 않는 Secret은 secretNotFound로 매핑한다")
    func decryptPayloadMapsMissingSecret() async {
        let missingID = UUID()
        let sut = DecryptSecretPayloadUseCaseImpl(
            repository: InMemorySecretRepository(),
            cryptoService: FakeSecretCryptoService()
        )

        await #expect(throws: SecretUseCaseError.secretNotFound(id: missingID)) {
            _ = try await sut.decryptPayload(id: missingID, as: APIKeyPayload.self)
        }
    }
}
