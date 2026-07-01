// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct SecretProjectRelationUseCaseImpl: SecretProjectRelationUseCase {
    private let repository: any SecretRepository

    public init(repository: any SecretRepository) {
        self.repository = repository
    }

    public func link(secretID: UUID, projectID: UUID) async throws {
        do {
            try await repository.linkProject(secretID: secretID, projectID: projectID)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func unlink(secretID: UUID, projectID: UUID) async throws {
        do {
            try await repository.unlinkProject(secretID: secretID, projectID: projectID)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
