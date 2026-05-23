// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol DeleteSecretUseCase: Sendable {
    func softDelete(id: UUID) async throws -> Secret
    func restore(id: UUID) async throws -> Secret
    func permanentlyDelete(id: UUID) async throws
}
