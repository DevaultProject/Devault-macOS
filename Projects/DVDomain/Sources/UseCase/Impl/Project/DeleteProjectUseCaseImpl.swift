// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct DeleteProjectUseCaseImpl: DeleteProjectUseCase {
    private let repository: any ProjectRepository

    public init(repository: any ProjectRepository) {
        self.repository = repository
    }

    public func delete(id: UUID) async throws {
        do {
            try await repository.delete(id: id)
        } catch {
            throw ProjectUseCaseError.map(error)
        }
    }
}
