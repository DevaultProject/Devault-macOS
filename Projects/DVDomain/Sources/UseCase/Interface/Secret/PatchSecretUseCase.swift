// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol PatchSecretUseCase: Sendable {
    func patch(id: UUID, with patch: SecretPatch) async throws -> Secret
    func updatePayload<Payload: SecretPayloadData>(
        id: UUID,
        payload: Payload
    ) async throws -> Secret
    func updateMetadata<Metadata: SecretMetadataContent>(
        id: UUID,
        metadata: Metadata
    ) async throws -> Secret
    func removeMetadata(id: UUID) async throws -> Secret
}
