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

    public func softDeleteAll(in collection: SecretQuery.Collection) async throws {
        do {
            // "소프트 삭제 = deletedAt·updatedAt 세팅"이라는 규칙은 유스케이스가 정하고(단건 softDelete와 동일),
            // 조회·전체 변경·저장의 원자성은 Repository가 단일 트랜잭션으로 책임진다.
            let now = dateProvider()
            try await repository.patchAll(
                matching: SecretQuery(collection: collection),
                with: SecretPatch(deletedAt: .set(now), updatedAt: .set(now))
            )
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func permanentlyDeleteAll(in collection: SecretQuery.Collection) async throws {
        do {
            try await repository.deleteAll(matching: SecretQuery(collection: collection))
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
