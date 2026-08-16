// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData
import Testing

@testable import DVData

@MainActor
@Suite("DataResetRepositoryImpl")
struct DataResetRepositoryImplTests {
    @Test("현재 ModelContainer의 Vault 데이터만 모두 삭제한다")
    func deleteAllRemovesVaultDataFromCurrentContainer() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Schema.appSchema,
            configurations: configuration
        )
        let context = ModelContext(container)

        let project = SwiftDataModel.Project(name: "Project")
        let secret = SwiftDataModel.Secret(name: "Secret", secretType: "apiKeyToken")
        let payload = SwiftDataModel.SecretPayload(
            encryptedData: Data([0x01]),
            keyTag: "key",
            schemaVersion: 1,
            secret: secret
        )
        let metadata = SwiftDataModel.SecretMetadata(
            metadataJSON: Data(),
            schemaVersion: 1,
            secret: secret
        )
        let link = SwiftDataModel.SecretProjectLink(project: project, secret: secret)
        let secretAuditLog = SwiftDataModel.SecretAuditLog(
            eventType: "created",
            actorContext: "test",
            secret: secret
        )
        let appAuditLog = SwiftDataModel.AppAuditLog(
            eventType: "launched",
            actorContext: "test"
        )
        let backupRecord = SwiftDataModel.BackupRecord(
            fileName: "backup.dvault",
            filePath: "/tmp/backup.dvault",
            backupScope: "all",
            hasIndependentPassword: false,
            keyTag: "backup-key",
            totalSecrets: 1
        )

        context.insert(project)
        context.insert(secret)
        context.insert(payload)
        context.insert(metadata)
        context.insert(link)
        context.insert(secretAuditLog)
        context.insert(appAuditLog)
        context.insert(backupRecord)
        try context.save()

        let repository = DataResetRepositoryImpl(modelContainer: container)
        try await repository.deleteAll()

        let verificationContext = ModelContext(container)
        let projectCount = try verificationContext.fetchCount(FetchDescriptor<SwiftDataModel.Project>())
        let secretCount = try verificationContext.fetchCount(FetchDescriptor<SwiftDataModel.Secret>())
        let payloadCount = try verificationContext.fetchCount(FetchDescriptor<SwiftDataModel.SecretPayload>())
        let metadataCount = try verificationContext.fetchCount(FetchDescriptor<SwiftDataModel.SecretMetadata>())
        let linkCount = try verificationContext.fetchCount(FetchDescriptor<SwiftDataModel.SecretProjectLink>())
        let secretAuditLogCount = try verificationContext.fetchCount(FetchDescriptor<SwiftDataModel.SecretAuditLog>())
        let appAuditLogCount = try verificationContext.fetchCount(FetchDescriptor<SwiftDataModel.AppAuditLog>())
        let backupRecordCount = try verificationContext.fetchCount(FetchDescriptor<SwiftDataModel.BackupRecord>())

        #expect(projectCount == 0)
        #expect(secretCount == 0)
        #expect(payloadCount == 0)
        #expect(metadataCount == 0)
        #expect(linkCount == 0)
        #expect(secretAuditLogCount == 0)
        #expect(appAuditLogCount == 0)
        #expect(backupRecordCount == 1)
    }
}
