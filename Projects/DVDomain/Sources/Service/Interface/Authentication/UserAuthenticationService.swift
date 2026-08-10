// Copyright © 2026 Devault. All rights reserved

/// 현재 사용자가 민감 작업을 수행할 수 있는지 로컬 인증으로 확인하는 서비스입니다.
public protocol UserAuthenticationService: Sendable {
    /// 로컬 인증(생체인증·PIN 등)을 요청한다. 인증 실패 시 에러를 throw한다.
    /// - Parameter reason: 인증 요청 시 사용자에게 표시할 이유 문구
    func authenticate(reason: String) async throws
}
