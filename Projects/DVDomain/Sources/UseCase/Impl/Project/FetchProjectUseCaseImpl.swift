// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct FetchProjectUseCaseImpl: FetchProjectUseCase {
    private let repository: any ProjectRepository

    public init(repository: any ProjectRepository) {
        self.repository = repository
    }

    public func fetch(id: UUID) async throws -> Project? {
        do {
            return try await repository.fetch(id: id)
        } catch {
            throw ProjectUseCaseError.map(error)
        }
    }

    public func fetchAll() async throws -> [Project] {
        do {
            return try await repository.fetchAll()
        } catch {
            throw ProjectUseCaseError.map(error)
        }
    }
}
