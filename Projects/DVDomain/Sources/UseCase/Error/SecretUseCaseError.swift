// Copyright © 2026 Devault. All rights reserved

import Foundation

public enum SecretUseCaseError: Error, Equatable, Sendable {
    case invalidName
    case invalidSecretType
    case secretNotFound(id: UUID)
    case repositoryFailure(SecretRepositoryError)
    case cryptoFailure(SecretCryptoError)
    case authenticationFailure(UserAuthenticationError)
    case unexpected
}

extension SecretUseCaseError {
    static func map(_ error: Error) -> SecretUseCaseError {
        if let error = error as? SecretUseCaseError {
            return error
        }

        if let error = error as? SecretRepositoryError {
            if case let .notFound(id) = error {
                return .secretNotFound(id: id)
            }
            return .repositoryFailure(error)
        }

        if let error = error as? SecretCryptoError {
            return .cryptoFailure(error)
        }

        if let error = error as? UserAuthenticationError {
            return .authenticationFailure(error)
        }

        return .unexpected
    }
}
