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
        payload: Payload,
        projectIDs: [UUID]
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
            return try await createAndLink(secret, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func execute<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        draft: SecretDraft,
        payload: Payload,
        metadata: Metadata,
        projectIDs: [UUID]
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
            return try await createAndLink(secret, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

}

private extension CreateSecretUseCaseImpl {
    func createAndLink(_ secret: Secret, projectIDs: [UUID]) async throws -> Secret {
        let created = try await repository.create(secret)
        do {
            for projectID in projectIDs {
                try await repository.linkProject(secretID: created.id, projectID: projectID)
            }
        } catch {
            try? await repository.delete(id: created.id)
            throw error
        }
        return created
    }
}
