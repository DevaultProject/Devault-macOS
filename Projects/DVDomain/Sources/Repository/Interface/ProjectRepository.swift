// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol ProjectRepository: Sendable {
    /// Project를 저장소에 생성한다.
    /// - Parameter project: 저장할 Project 엔티티
    /// - Returns: 저장된 Project
    func create(_ project: Project) async throws -> Project

    /// ID로 단일 Project를 조회한다.
    /// - Parameter id: 조회할 Project의 ID
    /// - Returns: 해당 Project. 존재하지 않으면 nil
    func fetch(id: UUID) async throws -> Project?

    /// 전체 Project 목록을 조회한다.
    /// - Returns: 저장된 모든 Project 배열
    func fetchAll() async throws -> [Project]

    /// Project의 지정 필드를 수정한다.
    /// - Parameters:
    ///   - id: 수정할 Project의 ID
    ///   - patch: 변경할 필드만 담은 ProjectPatch
    /// - Returns: 수정된 Project
    func patch(id: UUID, with patch: ProjectPatch) async throws -> Project

    /// Project를 영구 삭제한다.
    /// - Parameter id: 삭제할 Project의 ID
    func delete(id: UUID) async throws
}
