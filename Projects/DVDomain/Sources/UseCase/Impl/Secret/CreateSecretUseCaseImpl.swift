// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct CreateSecretUseCaseImpl: CreateSecretUseCase {
    private let repository: any SecretRepository
    private let cryptoService: any SecretCryptoService
    private let idGenerator: @Sendable () -> UUID
    private let dateProvider: @Sendable () -> Date

    public init(
        repository: any SecretRepository,
        cryptoService: any SecretCryptoService,
        idGenerator: @escaping @Sendable () -> UUID = { UUID() },
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.cryptoService = cryptoService
        self.idGenerator = idGenerator
        self.dateProvider = dateProvider
    }

    public func execute<Payload: SecretPayloadData>(
        draft: SecretDraft,
        payload: Payload
    ) async throws -> Secret {
        do {
            try SecretUseCaseHelper.validateDraft(draft)
            let now = dateProvider()
            let encryptedPayload = try await cryptoService.encryptPayload(payload)
            let secret = Secret(
                id: idGenerator(),
                name: draft.name,
                secretType: draft.secretType,
                subType: draft.subType,
                service: draft.service,
                environment: draft.environment,
                expiresAt: draft.expiresAt,
                memo: draft.memo,
                liked: draft.liked,
                createdAt: now,
                updatedAt: now,
                payload: encryptedPayload
            )
            return try await repository.create(secret)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func execute<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        draft: SecretDraft,
        payload: Payload,
        metadata: Metadata
    ) async throws -> Secret {
        do {
            try SecretUseCaseHelper.validateDraft(draft)
            let now = dateProvider()
            let encryptedPayload = try await cryptoService.encryptPayload(payload)
            let encodedMetadata = try cryptoService.encodeMetadata(metadata)
            let secret = Secret(
                id: idGenerator(),
                name: draft.name,
                secretType: draft.secretType,
                subType: draft.subType,
                service: draft.service,
                environment: draft.environment,
                expiresAt: draft.expiresAt,
                memo: draft.memo,
                liked: draft.liked,
                createdAt: now,
                updatedAt: now,
                payload: encryptedPayload,
                metadata: encodedMetadata
            )
            return try await repository.create(secret)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
