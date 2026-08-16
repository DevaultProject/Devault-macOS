// Copyright © 2026 Devault. All rights reserved

import SwiftData

import DVDomain

/// 현재 ModelContainer의 Vault 데이터를 삭제한다.
@ModelActor
public actor DataResetRepositoryImpl: DataResetRepository {
    public func deleteAll() async throws {
        do {
            let secretProjectLinks = try modelContext.fetch(FetchDescriptor<SwiftDataModel.SecretProjectLink>())
            let secretPayloads = try modelContext.fetch(FetchDescriptor<SwiftDataModel.SecretPayload>())
            let secretMetadata = try modelContext.fetch(FetchDescriptor<SwiftDataModel.SecretMetadata>())
            let secretAuditLogs = try modelContext.fetch(FetchDescriptor<SwiftDataModel.SecretAuditLog>())
            let secrets = try modelContext.fetch(FetchDescriptor<SwiftDataModel.Secret>())
            let projects = try modelContext.fetch(FetchDescriptor<SwiftDataModel.Project>())
            let appAuditLogs = try modelContext.fetch(FetchDescriptor<SwiftDataModel.AppAuditLog>())

            for model in secretProjectLinks { modelContext.delete(model) }
            for model in secretPayloads { modelContext.delete(model) }
            for model in secretMetadata { modelContext.delete(model) }
            for model in secretAuditLogs { modelContext.delete(model) }
            for model in secrets { modelContext.delete(model) }
            for model in projects { modelContext.delete(model) }
            for model in appAuditLogs { modelContext.delete(model) }

            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw DataResetRepositoryError.resetFailed
        }
    }
}
