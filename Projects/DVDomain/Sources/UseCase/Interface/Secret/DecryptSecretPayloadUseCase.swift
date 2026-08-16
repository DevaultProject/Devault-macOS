// Copyright © 2026 Devault. All rights reserved

import Foundation

/// Secret payload를 화면에 공개하지 않고 내부 동작에 사용할 수 있도록 복호화합니다.
public protocol DecryptSecretPayloadUseCase: Sendable {
    /// Secret의 암호화된 payload를 요청 타입으로 복호화한다.
    /// - Parameters:
    ///   - id: 조회할 Secret의 ID
    ///   - type: 복호화할 payload 타입
    /// - Returns: 복호화된 payload
    func decryptPayload<Payload: SecretPayloadData>(
        id: UUID,
        as type: Payload.Type
    ) async throws -> Payload
}
