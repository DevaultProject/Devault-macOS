// Copyright © 2026 Devault. All rights reserved

import SwiftData

import DVCore
import DVDomain

/// 현재 ModelContainer의 Secret·Project와 동기화 모델만 삭제한다.
/// `BackupRecord`는 로컬 백업 파일을 계속 찾고 복구할 수 있도록 의도적으로 유지한다.
/// Keychain 암호화 키는 저장소 범위 밖이며 같은 이유로 이 초기화에 포함하지 않는다.
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
            Log.error("Vault 데이터 초기화 실패: \(error)", category: .storage)
            throw DataResetRepositoryError.resetFailed
        }
    }
}
