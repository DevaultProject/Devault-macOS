// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class BackupRecord {
        var id: UUID = UUID()
        var fileName: String = ""
        var filePath: String = ""
        var backupScope: String = ""
        var hasIndependentPassword: Bool = false
        var keyTag: String = ""
        var totalSecrets: Int = 0
        var createdAt: Date = Date()

        init(
            id: UUID = UUID(),
            fileName: String,
            filePath: String,
            backupScope: String,
            hasIndependentPassword: Bool,
            keyTag: String,
            totalSecrets: Int,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.fileName = fileName
            self.filePath = filePath
            self.backupScope = backupScope
            self.hasIndependentPassword = hasIndependentPassword
            self.keyTag = keyTag
            self.totalSecrets = totalSecrets
            self.createdAt = createdAt
        }
    }
}
