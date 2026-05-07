// Copyright © 2026 Devault. All rights reserved

import SwiftData
import Foundation

extension SwiftDataModel {
    @Model final class Secret {
        @Attribute(.unique) var secretId: UUID
        var name: String
        var secretType: String
        var subType: String?
        var service: String?
        var environment: String?
        var expiresAt: Date?
        var memo: String?
        var liked: Bool
        var deletedAt: Date?
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \SwiftDataModel.SecretProjectLink.secret)
        var projectLinks: [SecretProjectLink]

        @Relationship(deleteRule: .cascade, inverse: \SwiftDataModel.SecretPayload.secret)
        var payload: SecretPayload?

        @Relationship(deleteRule: .cascade, inverse: \SwiftDataModel.SecretMetadata.secret)
        var metadata: [SecretMetadata]

        @Relationship(deleteRule: .cascade, inverse: \SwiftDataModel.SecretAuditLog.secret)
        var auditLogs: [SecretAuditLog]

        var projects: [Project] {
            projectLinks.compactMap(\.project)
        }

        init(
            secretId: UUID = UUID(),
            name: String,
            secretType: String,
            subType: String? = nil,
            service: String? = nil,
            environment: String? = nil,
            expiresAt: Date? = nil,
            memo: String? = nil,
            liked: Bool = false,
            deletedAt: Date? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.secretId = secretId
            self.name = name
            self.secretType = secretType
            self.subType = subType
            self.service = service
            self.environment = environment
            self.expiresAt = expiresAt
            self.memo = memo
            self.liked = liked
            self.deletedAt = deletedAt
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.projectLinks = []
            self.payload = nil
            self.metadata = []
            self.auditLogs = []
        }
    }
}
