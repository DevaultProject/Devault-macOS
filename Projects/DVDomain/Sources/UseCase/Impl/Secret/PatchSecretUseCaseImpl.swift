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

    public func updatePayload<Payload: SecretPayloadData>(
        id: UUID,
        payload: Payload
    ) async throws -> Secret {
        do {
            let encryptedPayload = try await cryptoService.encryptPayload(payload)
            let now = dateProvider()
            let patch = SecretPatch(
                payload: .set(encryptedPayload),
                updatedAt: .set(now)
            )
            return try await repository.patch(id: id, with: patch)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func updateMetadata<Metadata: SecretMetadataContent>(
        id: UUID,
        metadata: Metadata
    ) async throws -> Secret {
        do {
            let encodedMetadata = try cryptoService.encodeMetadata(metadata)
            let now = dateProvider()
            let patch = SecretPatch(
                metadata: .set(encodedMetadata),
                updatedAt: .set(now)
            )
            return try await repository.patch(id: id, with: patch)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func removeMetadata(id: UUID) async throws -> Secret {
        do {
            let now = dateProvider()
            let patch = SecretPatch(
                metadata: .set(nil),
                updatedAt: .set(now)
            )
            return try await repository.patch(id: id, with: patch)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
