// Copyright © 2026 Devault. All rights reserved

import Foundation

public enum SecretRepositoryError: Error, Equatable, Sendable {
    case notFound(id: UUID)
    case duplicateID(id: UUID)
    case projectNotFound(id: UUID)
    case duplicateProjectLink(secretID: UUID, projectID: UUID)
    case projectLinkNotFound(secretID: UUID, projectID: UUID)
    case invalidQuery
    case invalidPatch
    case corruptedStorage
    case storageUnavailable
    case persistenceFailed
}
