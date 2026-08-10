// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol RevealSecretPayloadUseCase: Sendable {
    /// 생체인증 후 Secret의 암호화된 payload를 복호화해 반환한다.
    /// `FetchSecretUseCase`와 분리해두는 이유는, 목록/개수 조회만 필요한 소비처(사이드바 카운트 등)가
    /// 인증 관련 의존성(`AuthenticateUseCase`)까지 억지로 조립하지 않아도 되게 하기 위함이다.
    /// - Parameters:
    ///   - id: 복호화할 Secret의 ID
    ///   - type: 복호화 결과로 변환할 payload 타입
    /// - Returns: 복호화된 payload
    func revealPayload<Payload: SecretPayloadData>(
        id: UUID,
        as type: Payload.Type
    ) async throws -> Payload
}
