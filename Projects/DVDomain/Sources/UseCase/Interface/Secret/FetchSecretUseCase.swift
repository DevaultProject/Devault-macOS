// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol FetchSecretUseCase: Sendable {
    func fetch(id: UUID) async throws -> Secret?
    func fetch(query: SecretQuery) async throws -> [Secret]
    func revealPayload<Payload: SecretPayloadData>(
        id: UUID,
        as type: Payload.Type
    ) async throws -> Payload
}
