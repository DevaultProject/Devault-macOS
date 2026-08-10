// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct RevealSecretPayloadUseCaseImpl: RevealSecretPayloadUseCase {
    private let repository: any SecretRepository
    private let cryptoService: any SecretCryptoService
    private let authenticateUseCase: any AuthenticateUseCase

    public init(
        repository: any SecretRepository,
        cryptoService: any SecretCryptoService,
        authenticateUseCase: any AuthenticateUseCase
    ) {
        self.repository = repository
        self.cryptoService = cryptoService
        self.authenticateUseCase = authenticateUseCase
    }

    public func revealPayload<Payload: SecretPayloadData>(
        id: UUID,
        as type: Payload.Type
    ) async throws -> Payload {
        do {
            try await authenticateUseCase.authenticate(reason: "Reveal secret payload")
            guard let secret = try await repository.fetch(id: id) else {
                throw SecretUseCaseError.secretNotFound(id: id)
            }
            return try await cryptoService.decryptPayload(secret.payload, as: type)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
