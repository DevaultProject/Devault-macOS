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

    public func update(
        id: UUID,
        patch: SecretPatch,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret {
        do {
            var fullPatch = try SecretUseCaseHelper.normalizedPatch(patch)
            fullPatch = SecretUseCaseHelper.settingUpdatedAtIfNeeded(fullPatch, now: dateProvider())
            return try await applyPatch(id: id, patch: fullPatch, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func update<Metadata: SecretMetadataContent>(
        id: UUID,
        patch: SecretPatch,
        metadata: Metadata,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret {
        do {
            // 정규화를 인코딩·암호화보다 먼저 한다 — 거부될 patch에 크립토 작업을 들일 이유가 없다.
            var fullPatch = try SecretUseCaseHelper.normalizedPatch(patch)
            let encodedMetadata = try cryptoService.encodeMetadata(metadata)
            fullPatch.metadata = .set(encodedMetadata)
            fullPatch = SecretUseCaseHelper.settingUpdatedAtIfNeeded(fullPatch, now: dateProvider())
            return try await applyPatch(id: id, patch: fullPatch, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func update<Payload: SecretPayloadData>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret {
        do {
            var fullPatch = try SecretUseCaseHelper.normalizedPatch(patch)
            let encryptedPayload = try await cryptoService.encryptPayload(payload)
            fullPatch.payload = .set(encryptedPayload)
            fullPatch = SecretUseCaseHelper.settingUpdatedAtIfNeeded(fullPatch, now: dateProvider())
            return try await applyPatch(id: id, patch: fullPatch, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func update<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        metadata: Metadata,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret {
        do {
            var fullPatch = try SecretUseCaseHelper.normalizedPatch(patch)
            let encryptedPayload = try await cryptoService.encryptPayload(payload)
            let encodedMetadata = try cryptoService.encodeMetadata(metadata)
            fullPatch.payload = .set(encryptedPayload)
            fullPatch.metadata = .set(encodedMetadata)
            fullPatch = SecretUseCaseHelper.settingUpdatedAtIfNeeded(fullPatch, now: dateProvider())
            return try await applyPatch(id: id, patch: fullPatch, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}

extension PatchSecretUseCaseImpl {
    private func applyPatch(id: UUID, patch: SecretPatch, projectIDs: PatchField<[UUID]>) async throws -> Secret {
        if case .set(let ids) = projectIDs {
            return try await repository.patch(id: id, with: patch, projectIDs: ids)
        }
        return try await repository.patch(id: id, with: patch)
    }
}
