// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol ProjectRepository: Sendable {
    /// Project를 저장소에 생성한다.
    /// - Parameter project: 저장할 Project 엔티티
    /// - Returns: 저장된 Project
    func create(_ project: Project) async throws -> Project

    /// 보유 수가 `limit` 미만일 때만 Project를 생성한다.
    ///
    /// 세는 것과 넣는 것을 한 번에 처리해, 동시에 들어온 생성 둘이 같은 개수를 보고 나란히 통과하는 틈을 없앤다. 한도가 얼마인지·언제 적용되는지는 호출부가 정하고 저장소는 받은 수만 지킨다.
    /// - Parameters:
    ///   - project: 저장할 Project 엔티티
    ///   - limit: 허용하는 보유 수
    /// - Returns: 저장된 Project. 한도에 걸려 만들지 않았으면 nil
    func create(_ project: Project, withinTotalLimit limit: Int) async throws -> Project?

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
