// Copyright © 2026 Devault. All rights reserved

@testable import DVDomain

/// 테스트용 UserAuthenticationService 구현. 결과와 마지막 reason을 기록한다.
public final class StubUserAuthenticationService: UserAuthenticationService, @unchecked Sendable {
    public var errorOnAuthenticate: UserAuthenticationError?

    public private(set) var authenticateCount = 0
    public private(set) var lastReason: AuthenticationReason?

    public init() {}

    public func authenticate(reason: AuthenticationReason) async throws {
        authenticateCount += 1
        lastReason = reason
        if let error = errorOnAuthenticate { throw error }
    }
}
