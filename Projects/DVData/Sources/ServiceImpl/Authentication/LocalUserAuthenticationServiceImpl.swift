// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation
import LocalAuthentication

public struct LocalUserAuthenticationServiceImpl: UserAuthenticationService {
    private let makeReason: @Sendable (AuthenticationReason) -> String

    /// LocalAuthentication 기반 사용자 인증 구현체를 생성한다.
    ///
    /// `makeReason`은 Data 모듈에서 Presentation의 로컬라이제이션 카탈로그에 접근할 수 없어
    /// 외부에서 주입받는다. 이 타입이 직접 가질 수 없는 관심사를 순수 함수로 밖에서 받는다.
    public init(makeReason: @escaping @Sendable (AuthenticationReason) -> String) {
        self.makeReason = makeReason
    }

    /// Touch ID 또는 시스템 암호로 현재 사용자를 인증한다.
    public func authenticate(reason: AuthenticationReason) async throws {
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw UserAuthenticationError.unavailable
        }

        try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: makeReason(reason)
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
