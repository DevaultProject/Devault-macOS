// Copyright © 2026 Devault. All rights reserved

public protocol CreateSecretUseCase: Sendable {
    func execute<Payload: SecretPayloadData>(
        draft: SecretDraft,
        payload: Payload
    ) async throws -> Secret

    func execute<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        draft: SecretDraft,
        payload: Payload,
        metadata: Metadata
    ) async throws -> Secret
}
