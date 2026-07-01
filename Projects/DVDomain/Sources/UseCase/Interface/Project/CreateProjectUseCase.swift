// Copyright © 2026 Devault. All rights reserved

public protocol CreateProjectUseCase: Sendable {
    func execute(name: String) async throws -> Project
}
