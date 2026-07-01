// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct PatchSecretUseCaseImpl: PatchSecretUseCase {
    private let repository: any SecretRepository
    private let cryptoService: any SecretCryptoService
    private let dateProvider: @Sendable () -> Date

    public init(
        repository: any SecretRepository,
        cryptoService: any SecretCryptoService,
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.cryptoService = cryptoService
        self.dateProvider = dateProvider
    }

    public func patch(id: UUID, with patch: SecretPatch) async throws -> Secret {
        do {
            let patch = SecretUseCaseHelper.settingUpdatedAtIfNeeded(patch, now: dateProvider())
            return try await repository.patch(id: id, with: patch)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func update<Payload: SecretPayloadData>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        projectIDs: [UUID]
    ) async throws -> Secret {
        do {
            let encryptedPayload = try await cryptoService.encryptPayload(payload)
            var fullPatch = patch
            fullPatch.payload = .set(encryptedPayload)
            fullPatch.updatedAt = .set(dateProvider())
            let updated = try await repository.patch(id: id, with: fullPatch)
            try await reconcileProjects(secretID: id, desiredIDs: projectIDs)
            return updated
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func update<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        metadata: Metadata,
        projectIDs: [UUID]
    ) async throws -> Secret {
        do {
            let encryptedPayload = try await cryptoService.encryptPayload(payload)
            let encodedMetadata = try cryptoService.encodeMetadata(metadata)
            var fullPatch = patch
            fullPatch.payload = .set(encryptedPayload)
            fullPatch.metadata = .set(encodedMetadata)
            fullPatch.updatedAt = .set(dateProvider())
            let updated = try await repository.patch(id: id, with: fullPatch)
            try await reconcileProjects(secretID: id, desiredIDs: projectIDs)
            return updated
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

}

private extension PatchSecretUseCaseImpl {
    func reconcileProjects(secretID: UUID, desiredIDs: [UUID]) async throws {
        let currentIDs = Set(try await repository.fetchProjects(secretID: secretID).map(\.id))
        let desiredIDs = Set(desiredIDs)
        for projectID in desiredIDs.subtracting(currentIDs) {
            try await repository.linkProject(secretID: secretID, projectID: projectID)
        }
        for projectID in currentIDs.subtracting(desiredIDs) {
            try await repository.unlinkProject(secretID: secretID, projectID: projectID)
        }
    }
}
