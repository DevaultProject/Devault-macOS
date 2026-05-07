// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class SecretProjectLink {
        var linkedAt: Date

        @Relationship
        var project: Project?

        @Relationship
        var secret: Secret?

        init(
            project: Project,
            secret: Secret,
            linkedAt: Date = Date()
        ) {
            self.linkedAt = linkedAt
            self.project = project
            self.secret = secret
        }
    }
}
