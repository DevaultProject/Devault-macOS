// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class SecretMetadata {
        @Attribute(.unique) var id: UUID
        @Attribute(.unique) var secretKey: String
        var metadataJSON: Data
        var schemaVersion: Int

        @Relationship
        var secret: Secret

        init(
            id: UUID = UUID(),
            metadataJSON: Data,
            schemaVersion: Int,
            secret: Secret
        ) {
            self.id = id
            self.secretKey = secret.secretId.uuidString
            self.metadataJSON = metadataJSON
            self.schemaVersion = schemaVersion
            self.secret = secret
        }
    }
}
