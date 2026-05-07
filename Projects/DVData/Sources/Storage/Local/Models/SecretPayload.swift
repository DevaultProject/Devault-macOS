// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class SecretPayload {
        @Attribute(.unique) var id: UUID
        @Attribute(.unique) var secretKey: String
        var encryptedData: Data
        var keyTag: String
        var schemaVersion: Int

        @Relationship
        var secret: Secret

        init(
            id: UUID = UUID(),
            encryptedData: Data,
            keyTag: String,
            schemaVersion: Int,
            secret: Secret
        ) {
            self.id = id
            self.secretKey = secret.secretId.uuidString
            self.encryptedData = encryptedData
            self.keyTag = keyTag
            self.schemaVersion = schemaVersion
            self.secret = secret
        }
    }
}
