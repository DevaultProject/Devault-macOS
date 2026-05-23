// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct SecretMetadata: Equatable, Identifiable, Sendable {
    public var id: UUID
    public var metadataJSON: Data
    public var schemaVersion: Int

    public init(
        id: UUID,
        metadataJSON: Data,
        schemaVersion: Int
    ) {
        self.id = id
        self.metadataJSON = metadataJSON
        self.schemaVersion = schemaVersion
    }
}
