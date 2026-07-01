// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol RenameProjectUseCase: Sendable {
    func rename(id: UUID, name: String) async throws -> Project
}
