// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class SecretMetadata {
        var id: UUID = UUID()
        var metadataJSON: Data = Data()
        var schemaVersion: Int = 1

        @Relationship
        var secret: Secret?

        init(
            id: UUID = UUID(),
            metadataJSON: Data,
            schemaVersion: Int,
            secret: Secret
        ) {
            self.id = id
            self.metadataJSON = metadataJSON
            self.schemaVersion = schemaVersion
            self.secret = secret
        }
    }
}

extension SwiftDataModel.SecretMetadata {
    func toDomain() -> DVDomain.SecretMetadata {
        DVDomain.SecretMetadata(
            metadataJSON: metadataJSON,
            schemaVersion: schemaVersion
        )
    }
}
