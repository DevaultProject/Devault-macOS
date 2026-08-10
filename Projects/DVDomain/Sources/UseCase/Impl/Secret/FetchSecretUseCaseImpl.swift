// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct FetchSecretUseCaseImpl: FetchSecretUseCase {
    private let repository: any SecretRepository

    public init(repository: any SecretRepository) {
        self.repository = repository
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

    public func count(query: SecretQuery) async throws -> Int {
        do {
            return try await repository.count(query)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func fetchProjects(secretID: UUID) async throws -> [Project] {
        do {
            return try await repository.fetchProjects(secretID: secretID)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
