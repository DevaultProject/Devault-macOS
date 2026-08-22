// Copyright © 2026 Devault. All rights reserved

import Foundation

public enum SecretUseCaseError: Error, Equatable, Sendable {
    case invalidName
    case invalidSecretType
    case secretNotFound(id: UUID)
    case repositoryFailure(SecretRepositoryError)
    case cryptoFailure(SecretCryptoError)
    case authenticationFailure(UserAuthenticationError)
    /// 보유 수가 무료 티어 한도를 넘겨 수정이 잠긴 상태. 조회·복사·즐겨찾기·삭제는 계속 허용된다.
    case editLockedByEntitlement
    case unexpected
}

extension SecretUseCaseError {
    public static func map(_ error: Error) -> SecretUseCaseError {
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
