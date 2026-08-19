// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("RevealSecretPayloadUseCaseImpl")
struct RevealSecretPayloadUseCaseImplTests {

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
        let sut = makeSUT(repository: repo, cryptoService: crypto, authenticationService: auth)

        let revealed: APIKeyPayload = try await sut.revealPayload(id: secret.id, as: APIKeyPayload.self, reason: .revealSecret)

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
        let sut = makeSUT(repository: repo, cryptoService: crypto, authenticationService: auth)

        await #expect(throws: SecretUseCaseError.authenticationFailure(.cancelled)) {
            _ = try await sut.revealPayload(id: UUID(), as: APIKeyPayload.self, reason: .revealSecret)
        }
        #expect(repo.fetchByIDCount == 0)
        #expect(crypto.decryptCount == 0)
    }

    @Test("존재하지 않는 Secret은 secretNotFound로 매핑되고 decrypt는 호출되지 않는다")
    func revealPayloadSecretNotFound() async {
        let repo = InMemorySecretRepository()
        let crypto = FakeSecretCryptoService()
        let missingID = UUID()
        let sut = makeSUT(repository: repo, cryptoService: crypto, authenticationService: StubUserAuthenticationService())

        await #expect(throws: SecretUseCaseError.secretNotFound(id: missingID)) {
            _ = try await sut.revealPayload(id: missingID, as: APIKeyPayload.self, reason: .revealSecret)
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
        let sut = makeSUT(repository: repo, cryptoService: crypto, authenticationService: StubUserAuthenticationService())

        await #expect(throws: SecretUseCaseError.cryptoFailure(.decryptionFailed)) {
            _ = try await sut.revealPayload(id: secret.id, as: APIKeyPayload.self, reason: .revealSecret)
        }
    }

    @Test("복사 인증 설정이 꺼져 있어도 reveal은 항상 인증한다")
    func revealPayloadAlwaysAuthenticatesWhenCopyAuthIsDisabled() async throws {
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
        let settingsRepository = FakeSettingsRepository()
        settingsRepository.isRequireAuthToCopyEnabledValue = false
        let sut = makeSUT(
            repository: repo,
            cryptoService: crypto,
            authenticationService: auth,
            settingsRepository: settingsRepository
        )

        let revealed: APIKeyPayload = try await sut.revealPayload(
            id: secret.id,
            as: APIKeyPayload.self,
            reason: .revealSecret
        )

        #expect(revealed == payload)
        #expect(auth.authenticateCount == 1)
        #expect(auth.lastReason == .revealSecret)
    }

    // MARK: - Helpers

    private func makeSUT(
        repository: InMemorySecretRepository,
        cryptoService: FakeSecretCryptoService,
        authenticationService: StubUserAuthenticationService,
        settingsRepository: FakeSettingsRepository = FakeSettingsRepository()
    ) -> RevealSecretPayloadUseCaseImpl {
        RevealSecretPayloadUseCaseImpl(
            decryptPayloadUseCase: DecryptSecretPayloadUseCaseImpl(
                repository: repository,
                cryptoService: cryptoService
            ),
            authenticateUseCase: AuthenticateUseCaseImpl(
                authenticationService: authenticationService,
                notificationService: FakeSecurityNotificationService(),
                settingsRepository: settingsRepository
            )
        )
    }
}
