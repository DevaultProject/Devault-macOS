// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class SecretAuditLog {
        var id: UUID = UUID()
        var eventType: String = ""
        var actorContext: String = ""
        var isSuspicious: Bool = false
        var occurredAt: Date = Date()

        // MARK: - Snapshot field
        var secretSnapshotId: UUID = UUID()
        var secretNameSnapshot: String = ""
        var secretTypeSnapshot: String = ""

        @Relationship
        var secret: Secret?

        init(
            id: UUID = UUID(),
            eventType: String,
            actorContext: String,
            isSuspicious: Bool = false,
            occurredAt: Date = Date(),
            secret: Secret
        ) {
            self.id = id
            self.eventType = eventType
            self.actorContext = actorContext
            self.isSuspicious = isSuspicious
            self.occurredAt = occurredAt
            self.secretSnapshotId = secret.id
            self.secretNameSnapshot = secret.name
            self.secretTypeSnapshot = secret.secretType
            self.secret = secret
        }
    }
}
