// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol DeleteProjectUseCase: Sendable {
    /// Project를 영구 삭제한다. 복구 불가.
    /// - Parameter id: 삭제할 Project의 ID
    func delete(id: UUID) async throws
}
