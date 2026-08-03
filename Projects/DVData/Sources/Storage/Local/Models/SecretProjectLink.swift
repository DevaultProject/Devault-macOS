// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData

extension SwiftDataModel {
    @Model final class SecretProjectLink {
        var linkKey: String = ""
        var linkedAt: Date = Date()

        // 관계(project/secret)가 아직 CloudKit에서 동기화되지 않아 nil인 순간에도
        // "이 링크가 어떤 project/secret을 가리키는지"를 판단할 수 있도록 스칼라로도 들고 있는다.
        // (SecretAuditLog가 secretSnapshotId를 스냅샷으로 들고 있는 것과 같은 패턴)
        var projectID: UUID = UUID()
        var secretID: UUID = UUID()

        @Relationship
        var project: Project?

        @Relationship
        var secret: Secret?

        init(
            project: Project,
            secret: Secret,
            linkedAt: Date = Date()
        ) {
            self.linkKey = "\(project.id.uuidString):\(secret.id.uuidString)"
            self.linkedAt = linkedAt
            self.projectID = project.id
            self.secretID = secret.id
            self.project = project
            self.secret = secret
        }
    }
}
