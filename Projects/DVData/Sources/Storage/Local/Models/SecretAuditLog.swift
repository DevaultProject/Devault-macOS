// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class SecretAuditLog {
        @Attribute(.unique) var id: UUID
        var eventType: String
        var actorContext: String
        var isSuspicious: Bool
        var occurredAt: Date

        @Relationship
        var secret: Secret?

        init(
            id: UUID = UUID(),
            eventType: String,
            actorContext: String,
            isSuspicious: Bool = false,
            occurredAt: Date = Date(),
            secret: Secret? = nil
        ) {
            self.id = id
            self.eventType = eventType
            self.actorContext = actorContext
            self.isSuspicious = isSuspicious
            self.occurredAt = occurredAt
            self.secret = secret
        }
    }
}
