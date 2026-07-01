// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol PatchSecretUseCase: Sendable {
    func patch(id: UUID, with patch: SecretPatch) async throws -> Secret
    func update<Payload: SecretPayloadData>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        projectIDs: [UUID]
    ) async throws -> Secret
    func update<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        metadata: Metadata,
        projectIDs: [UUID]
    ) async throws -> Secret
}
