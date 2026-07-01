// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol DeleteProjectUseCase: Sendable {
    func delete(id: UUID) async throws
}
