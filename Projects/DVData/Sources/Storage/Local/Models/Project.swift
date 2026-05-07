// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class Project {
        @Attribute(.unique) var id: UUID
        var name: String
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \SwiftDataModel.SecretProjectLink.project)
        var secretLinks: [SecretProjectLink]

        var secrets: [Secret] {
            secretLinks.compactMap(\.secret)
        }

        init(
            id: UUID = UUID(),
            name: String,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.secretLinks = []
        }
    }
}
