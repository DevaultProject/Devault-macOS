// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct SecretPayload: Equatable, Identifiable, Sendable {
    public var id: UUID
    public var encryptedData: Data
    public var keyTag: String
    public var schemaVersion: Int

    public init(
        id: UUID,
        encryptedData: Data,
        keyTag: String,
        schemaVersion: Int
    ) {
        self.id = id
        self.encryptedData = encryptedData
        self.keyTag = keyTag
        self.schemaVersion = schemaVersion
    }
}
