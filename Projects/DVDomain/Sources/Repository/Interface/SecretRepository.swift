// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol SecretRepository: Sendable {
    func create(_ secret: Secret) async throws -> Secret
    func fetch(id: UUID) async throws -> Secret?
    func fetch(_ query: SecretQuery) async throws -> [Secret]
    func patch(id: UUID, with patch: SecretPatch) async throws -> Secret
    func delete(id: UUID) async throws
}
