// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol SecretProjectRelationUseCase: Sendable {
    func link(secretID: UUID, projectID: UUID) async throws
    func unlink(secretID: UUID, projectID: UUID) async throws
}
