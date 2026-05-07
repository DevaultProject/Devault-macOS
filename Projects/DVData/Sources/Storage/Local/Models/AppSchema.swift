// Copyright © 2026 Devault. All rights reserved

import SwiftData

enum SwiftDataModel { }

extension Schema {
    private static let actualVersion: Schema.Version = Version(1, 0, 0)

    static var appSchema: Schema {
        Schema([
            SwiftDataModel.Project.self,
            SwiftDataModel.Secret.self,
            SwiftDataModel.SecretProjectLink.self,
            SwiftDataModel.SecretPayload.self,
            SwiftDataModel.SecretMetadata.self,
            SwiftDataModel.SecretAuditLog.self,
            SwiftDataModel.AppAuditLog.self,
            SwiftDataModel.BackupRecord.self,
        ], version: actualVersion)
    }
}
