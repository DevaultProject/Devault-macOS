// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVCore
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
            Log.info("[Preview mock] ProjectClient.fetchProjects 호출됨", category: .domain)
            let projects = [
                Project(id: UUID(), name: "Backend",        createdAt: Date(), updatedAt: Date()),
                Project(id: UUID(), name: "Mobile",         createdAt: Date(), updatedAt: Date()),
                Project(id: UUID(), name: "Infrastructure", createdAt: Date(), updatedAt: Date()),
            ]
            Log.debug("[Preview mock] → \(projects.count) projects 반환", category: .domain)
            return projects
        }
    )
}

public extension DependencyValues {
    var projectClient: ProjectClient {
        get { self[ProjectClient.self] }
        set { self[ProjectClient.self] = newValue }
    }
}
