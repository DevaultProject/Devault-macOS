// Copyright © 2026 Devault. All rights reserved

import SwiftData

enum SwiftDataModel { }

extension Schema {
    private static let schemaVersion: Schema.Version = Version(1, 0, 0)

    /// iCloud와 동기화되는 모델. CloudKit private database로 미러링 됨
    static let syncedSchema = Schema([
        SwiftDataModel.Project.self,
        SwiftDataModel.Secret.self,
        SwiftDataModel.SecretProjectLink.self,
        SwiftDataModel.SecretPayload.self,
        SwiftDataModel.SecretMetadata.self,
        SwiftDataModel.SecretAuditLog.self,
        SwiftDataModel.AppAuditLog.self,
    ], version: schemaVersion)

    /// 기기 로컬에만 저장되는 모델.
    /// BackupRecord.filePath는 해당 기기의 절대 경로라 다른 기기에서는 의미가 없고,
    /// 사용자명 등 로컬 경로 정보가 그대로 iCloud에 올라가면 안 되므로 동기화 스코프에서 제외
    static let localOnlySchema = Schema([
        SwiftDataModel.BackupRecord.self,
    ], version: schemaVersion)

    static let appSchema = Schema([
        SwiftDataModel.Project.self,
        SwiftDataModel.Secret.self,
        SwiftDataModel.SecretProjectLink.self,
        SwiftDataModel.SecretPayload.self,
        SwiftDataModel.SecretMetadata.self,
        SwiftDataModel.SecretAuditLog.self,
        SwiftDataModel.AppAuditLog.self,
        SwiftDataModel.BackupRecord.self,
    ], version: schemaVersion)
}
