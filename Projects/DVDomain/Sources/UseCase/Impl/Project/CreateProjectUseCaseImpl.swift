// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct CreateProjectUseCaseImpl: CreateProjectUseCase {
    private let repository: any ProjectRepository
    private let idGenerator: @Sendable () -> UUID
    private let dateProvider: @Sendable () -> Date

    public init(
        repository: any ProjectRepository,
        idGenerator: @escaping @Sendable () -> UUID = { UUID() },
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.idGenerator = idGenerator
        self.dateProvider = dateProvider
    }

    public func execute(name: String) async throws -> Project {
        do {
            let normalizedName = try ProjectUseCaseHelper.normalizedName(name)
            let now = dateProvider()
            let project = Project(
                id: idGenerator(),
                name: normalizedName,
                createdAt: now,
                updatedAt: now
            )
            return try await repository.create(project)
        } catch {
            throw ProjectUseCaseError.map(error)
        }
    }
}
