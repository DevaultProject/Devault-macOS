// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct DecryptSecretPayloadUseCaseImpl: DecryptSecretPayloadUseCase {
    private let repository: any SecretRepository
    private let cryptoService: any SecretCryptoService

    public init(
        repository: any SecretRepository,
        cryptoService: any SecretCryptoService
    ) {
        self.repository = repository
        self.cryptoService = cryptoService
    }

    public func decryptPayload<Payload: SecretPayloadData>(
        id: UUID,
        as type: Payload.Type
    ) async throws -> Payload {
        do {
            guard let secret = try await repository.fetch(id: id) else {
                throw SecretUseCaseError.secretNotFound(id: id)
            }
            return try await cryptoService.decryptPayload(secret.payload, as: type)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
