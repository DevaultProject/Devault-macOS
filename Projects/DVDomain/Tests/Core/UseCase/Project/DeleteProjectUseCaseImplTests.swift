// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("DeleteProjectUseCaseImpl")
struct DeleteProjectUseCaseImplTests {
    @Test("존재하는 Project를 삭제하면 저장소에서 제거된다")
    func deleteHappyPath() async throws {
        let repo = InMemoryProjectRepository()
        let project = ProjectFixture.make()
        repo.seed(project)
        let sut = DeleteProjectUseCaseImpl(repository: repo)

        try await sut.delete(id: project.id)

        #expect(repo.deleteCount == 1)
        #expect(repo.projects[project.id] == nil)
    }

    @Test("존재하지 않는 id는 projectNotFound로 매핑된다")
    func deleteMapsNotFound() async {
        let missingID = UUID()
        let sut = DeleteProjectUseCaseImpl(repository: InMemoryProjectRepository())

        await #expect(throws: ProjectUseCaseError.projectNotFound(id: missingID)) {
            try await sut.delete(id: missingID)
        }
    }

    @Test("Repository.delete 실패는 repositoryFailure로 매핑된다")
    func deleteMapsRepositoryFailure() async {
        let repo = InMemoryProjectRepository()
        repo.seed(ProjectFixture.make())
        repo.errorOnDelete = .persistenceFailed
        let sut = DeleteProjectUseCaseImpl(repository: repo)

        await #expect(throws: ProjectUseCaseError.repositoryFailure(.persistenceFailed)) {
            try await sut.delete(id: ProjectFixture.fixedID)
        }
    }
}
