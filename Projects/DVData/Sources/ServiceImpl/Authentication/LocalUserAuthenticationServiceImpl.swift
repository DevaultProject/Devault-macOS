// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation
import LocalAuthentication

public struct LocalUserAuthenticationServiceImpl: UserAuthenticationService {
    /// LocalAuthentication 기반 사용자 인증 구현체를 생성한다.
    public init() {}

    /// Touch ID 또는 시스템 암호로 현재 사용자를 인증한다.
    public func authenticate(reason: String) async throws {
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw UserAuthenticationError.unavailable
        }

        try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            ) { success, error in
                if success {
                    continuation.resume()
                    return
                }

                if let error = error as? LAError {
                    switch error.code {
                    case .userCancel, .systemCancel, .appCancel:
                        continuation.resume(throwing: UserAuthenticationError.cancelled)
                    default:
                        continuation.resume(throwing: UserAuthenticationError.failed)
                    }
                    return
                }

                continuation.resume(throwing: UserAuthenticationError.failed)
            }
        }
    }
}
