// Copyright © 2026 Devault. All rights reserved

import DVDomain
import SwiftData
import Foundation

extension SwiftDataModel {
    @Model final class Secret {
        var id: UUID
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
        var metadata: SecretMetadata?

        @Relationship(deleteRule: .nullify, inverse: \SwiftDataModel.SecretAuditLog.secret)
        var auditLogs: [SecretAuditLog]

        /// `SecretProjectLink`를 통해 연결된 프로젝트 목록을 반환하는 편의 접근자입니다.
        var projects: [Project] {
            projectLinks.compactMap(\.project)
        }

        init(
            id: UUID = UUID(),
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
            updatedAt: Date? = nil
        ) {
            let initialCreatedAt = createdAt
            self.id = id
            self.name = name
            self.secretType = secretType
            self.subType = subType
            self.service = service
            self.environment = environment
            self.expiresAt = expiresAt
            self.memo = memo
            self.liked = liked
            self.deletedAt = deletedAt
            self.createdAt = initialCreatedAt
            self.updatedAt = updatedAt ?? initialCreatedAt
            self.projectLinks = []
            self.payload = nil
            self.metadata = nil
            self.auditLogs = []
        }
    }
}

extension SwiftDataModel.Secret {
    func toDomain() throws -> DVDomain.Secret {
        guard let payload else {
            throw SecretRepositoryError.corruptedStorage
        }

        guard let domainSecretType = DVDomain.SecretType(rawValue: secretType) else {
            throw SecretRepositoryError.corruptedStorage
        }
        let domainSubType: DVDomain.SecretSubType?
        if let subType {
            guard let parsedSubType = DVDomain.SecretSubType(rawValue: subType) else {
                throw SecretRepositoryError.corruptedStorage
            }
            domainSubType = parsedSubType
        } else {
            domainSubType = nil
        }

        return DVDomain.Secret(
            id: id,
            name: name,
            secretType: domainSecretType,
            subType: domainSubType,
            service: service,
            environment: environment,
            expiresAt: expiresAt,
            memo: memo,
            liked: liked,
            deletedAt: deletedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            payload: payload.toDomain(),
            metadata: metadata?.toDomain()
        )
    }
}
