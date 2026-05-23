// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct FetchSecretUseCaseImpl: FetchSecretUseCase {
    private let repository: any SecretRepository
    private let cryptoService: any SecretCryptoService

    public init(
        repository: any SecretRepository,
        cryptoService: any SecretCryptoService
    ) {
        self.repository = repository
        self.cryptoService = cryptoService
    }

    public func fetch(id: UUID) async throws -> Secret? {
        do {
            return try await repository.fetch(id: id)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func fetch(query: SecretQuery) async throws -> [Secret] {
        do {
            return try await repository.fetch(query)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func revealPayload<Payload: SecretPayloadData>(
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
