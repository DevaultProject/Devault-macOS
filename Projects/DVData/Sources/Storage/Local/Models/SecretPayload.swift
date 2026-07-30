// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class SecretPayload {
        var id: UUID = UUID()
        var encryptedData: Data = Data()
        var keyTag: String = ""
        var schemaVersion: Int = 1

        @Relationship
        var secret: Secret?

        init(
            id: UUID = UUID(),
            encryptedData: Data,
            keyTag: String,
            schemaVersion: Int,
            secret: Secret
        ) {
            self.id = id
            self.encryptedData = encryptedData
            self.keyTag = keyTag
            self.schemaVersion = schemaVersion
            self.secret = secret
        }
    }
}

extension SwiftDataModel.SecretPayload {
    func toDomain() -> DVDomain.SecretPayload {
        DVDomain.SecretPayload(
            encryptedData: encryptedData,
            keyTag: keyTag,
            schemaVersion: schemaVersion
        )
    }
}
