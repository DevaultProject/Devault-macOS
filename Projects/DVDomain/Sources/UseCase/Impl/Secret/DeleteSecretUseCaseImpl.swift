// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct DeleteSecretUseCaseImpl: DeleteSecretUseCase {
    private let repository: any SecretRepository
    private let dateProvider: @Sendable () -> Date

    public init(
        repository: any SecretRepository,
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.dateProvider = dateProvider
    }

    public func softDelete(id: UUID) async throws -> Secret {
        do {
            let now = dateProvider()
            let patch = SecretPatch(
                deletedAt: .set(now),
                updatedAt: .set(now)
            )
            return try await repository.patch(id: id, with: patch)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func restore(id: UUID) async throws -> Secret {
        do {
            let now = dateProvider()
            let patch = SecretPatch(
                deletedAt: .set(nil),
                updatedAt: .set(now)
            )
            return try await repository.patch(id: id, with: patch)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func permanentlyDelete(id: UUID) async throws {
        do {
            try await repository.delete(id: id)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
