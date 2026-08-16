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
        as type: Payload.Type
    ) async throws -> Payload {
        do {
            try await authenticateUseCase.authenticate(reason: AuthenticationReason.revealSecret)
            return try await decryptPayloadUseCase.decryptPayload(id: id, as: type)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
