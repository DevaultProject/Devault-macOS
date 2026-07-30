// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class AppAuditLog {
        var id: UUID = UUID()
        var eventType: String = ""
        var actorContext: String = ""
        var occurredAt: Date = Date()

        init(
            id: UUID = UUID(),
            eventType: String,
            actorContext: String,
            occurredAt: Date = Date()
        ) {
            self.id = id
            self.eventType = eventType
            self.actorContext = actorContext
            self.occurredAt = occurredAt
        }
    }
}
