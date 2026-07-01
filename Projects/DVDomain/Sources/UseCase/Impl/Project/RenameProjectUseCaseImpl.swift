// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct RenameProjectUseCaseImpl: RenameProjectUseCase {
    private let repository: any ProjectRepository
    private let dateProvider: @Sendable () -> Date

    public init(
        repository: any ProjectRepository,
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.dateProvider = dateProvider
    }

    public func rename(id: UUID, name: String) async throws -> Project {
        do {
            let normalizedName = try ProjectUseCaseHelper.normalizedName(name)
            let patch = ProjectPatch(
                name: .set(normalizedName),
                updatedAt: .set(dateProvider())
            )
            return try await repository.patch(id: id, with: patch)
        } catch {
            throw ProjectUseCaseError.map(error)
        }
    }
}
