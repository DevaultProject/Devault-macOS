// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class Project {
        var id: UUID
        var name: String
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \SwiftDataModel.SecretProjectLink.project)
        var secretLinks: [SecretProjectLink]

        /// `SecretProjectLink`를 통해 연결된 시크릿 목록을 반환하는 편의 접근자입니다.
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

extension SwiftDataModel.Project {
    func toDomain() -> DVDomain.Project {
        DVDomain.Project(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
