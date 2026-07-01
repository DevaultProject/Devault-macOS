// Copyright © 2026 Devault. All rights reserved

import Foundation

public enum ProjectRepositoryError: Error, Equatable, Sendable {
    case notFound(id: UUID)
    case duplicateID(id: UUID)
    case duplicateName(name: String)
    case invalidPatch
    case corruptedStorage
    case storageUnavailable
    case persistenceFailed
}
