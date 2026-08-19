// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct RevealSecretPayloadUseCaseImpl: RevealSecretPayloadUseCase {
    private let decryptPayloadUseCase: any DecryptSecretPayloadUseCase
    private let authenticateUseCase: any AuthenticateUseCase

    public init(
        decryptPayloadUseCase: any DecryptSecretPayloadUseCase,
        authenticateUseCase: any AuthenticateUseCase
    ) {
        self.decryptPayloadUseCase = decryptPayloadUseCase
        self.authenticateUseCase = authenticateUseCase
    }

    public func revealPayload<Payload: SecretPayloadData>(
        id: UUID,
        as type: Payload.Type,
        reason: AuthenticationReason
    ) async throws -> Payload {
        do {
            // 사유는 호출자가 정한다 — 열람과 수정 진입이 같은 복호화를 타지만 사용자가 누른
            // 버튼이 달라서다. 기본값을 두지 않아 호출부가 고르는 것을 잊을 수 없다.
            try await authenticateUseCase.authenticate(reason: reason)
            return try await decryptPayloadUseCase.decryptPayload(id: id, as: type)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
