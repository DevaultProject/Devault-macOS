// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation

/// Project 조회 Client. Create/Main/ProjectDetail 등 여러 Feature가 공유.
/// Live 조립은 Devault(App 타겟)에서 `FetchProjectUseCase.fetchAll()`을 wrap.
@DependencyClient
public struct ProjectClient: Sendable {
    
    /// 저장된 모든 Project 목록을 조회한다.
    public var fetchProjects: @Sendable () async throws -> [Project]
}

extension ProjectClient: TestDependencyKey {
    public static let testValue = ProjectClient()
    
    public static let previewValue = ProjectClient(
        fetchProjects: {
            [
                Project(id: UUID(), name: "Backend",        createdAt: Date(), updatedAt: Date()),
                Project(id: UUID(), name: "Mobile",         createdAt: Date(), updatedAt: Date()),
                Project(id: UUID(), name: "Infrastructure", createdAt: Date(), updatedAt: Date()),
            ]
        }
    )
}

public extension DependencyValues {
    var projectClient: ProjectClient {
        get { self[ProjectClient.self] }
        set { self[ProjectClient.self] = newValue }
    }
}
