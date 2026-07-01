// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol CreateSecretUseCase: Sendable {
    func execute<Payload: SecretPayloadData>(
        draft: SecretDraft,
        payload: Payload,
        projectIDs: [UUID]
    ) async throws -> Secret

    func execute<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        draft: SecretDraft,
        payload: Payload,
        metadata: Metadata,
        projectIDs: [UUID]
    ) async throws -> Secret
}
