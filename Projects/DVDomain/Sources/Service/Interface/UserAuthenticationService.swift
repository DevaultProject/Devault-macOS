// Copyright © 2026 Devault. All rights reserved

/// 현재 사용자가 민감 작업을 수행할 수 있는지 로컬 인증으로 확인하는 서비스입니다.
public protocol UserAuthenticationService: Sendable {
    func authenticate(reason: String) async throws
}
