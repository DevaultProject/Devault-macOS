// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol FetchProjectUseCase: Sendable {
    /// ID로 단일 Project를 조회한다.
    /// - Parameter id: 조회할 Project의 ID
    /// - Returns: 해당 Project. 존재하지 않으면 nil
    func fetch(id: UUID) async throws -> Project?

    /// 전체 Project 목록을 조회한다.
    /// - Returns: 저장된 모든 Project 배열
    func fetchAll() async throws -> [Project]
}
