// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol FetchProjectUseCase: Sendable {
    func fetch(id: UUID) async throws -> Project?
    func fetchAll() async throws -> [Project]
}
