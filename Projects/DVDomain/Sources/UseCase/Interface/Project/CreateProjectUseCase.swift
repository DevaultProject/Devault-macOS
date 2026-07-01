// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol CreateProjectUseCase: Sendable {
    /// Project를 생성한다.
    /// - Parameter name: 생성할 Project의 이름
    /// - Returns: 생성된 Project
    func execute(name: String) async throws -> Project
}
