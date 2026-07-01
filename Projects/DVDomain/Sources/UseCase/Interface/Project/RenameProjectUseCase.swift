// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol RenameProjectUseCase: Sendable {
    /// Project의 이름을 변경한다.
    /// - Parameters:
    ///   - id: 이름을 변경할 Project의 ID
    ///   - name: 변경할 새 이름
    /// - Returns: 이름이 변경된 Project
    func rename(id: UUID, name: String) async throws -> Project
}
