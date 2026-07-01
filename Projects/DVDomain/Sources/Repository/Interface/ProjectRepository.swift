// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol ProjectRepository: Sendable {
    func create(_ project: Project) async throws -> Project
    func fetch(id: UUID) async throws -> Project?
    func fetchAll() async throws -> [Project]
    func patch(id: UUID, with patch: ProjectPatch) async throws -> Project
    func delete(id: UUID) async throws
}
