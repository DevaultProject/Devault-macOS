// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

/// Lock Feature 전용 Client. 잠금 해제(Touch ID/시스템 암호 인증)에서 사용.
/// Main → Lock으로 다시 돌아오는 흐름(재잠금 등)에서도 동일하게 재사용.
@DependencyClient
public struct LockClient: Sendable {

    /// Touch ID 또는 시스템 암호로 잠금을 해제한다. 실패 시 `UserAuthenticationError`를 throw한다.
    public var unlock: @Sendable () async throws -> Void
}

extension LockClient: TestDependencyKey {
    public static let testValue = LockClient()

    public static let previewValue = LockClient(
        unlock: { }
    )
}

extension DependencyValues {
    public var lockClient: LockClient {
        get { self[LockClient.self] }
        set { self[LockClient.self] = newValue }
    }
}
