// Copyright © 2026 Devault. All rights reserved

import Foundation

public enum ProjectUseCaseError: Error, Equatable, Sendable {
    case invalidName
    case projectNotFound(id: UUID)
    case repositoryFailure(ProjectRepositoryError)
    case unexpected
}

extension ProjectUseCaseError {
    public static func map(_ error: Error) -> ProjectUseCaseError {
        if let error = error as? ProjectUseCaseError {
            return error
        }

        if let error = error as? ProjectRepositoryError {
            if case let .notFound(id) = error {
                return .projectNotFound(id: id)
            }
            return .repositoryFailure(error)
        }

        return .unexpected
    }
}
