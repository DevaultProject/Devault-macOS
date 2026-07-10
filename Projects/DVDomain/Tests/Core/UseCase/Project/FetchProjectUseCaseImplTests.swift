// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("FetchProjectUseCaseImpl")
struct FetchProjectUseCaseImplTests {
    // MARK: - fetch(id:)

    @Test("존재하는 id로 조회하면 해당 Project를 반환한다")
    func fetchByIDReturnsProject() async throws {
        let repo = InMemoryProjectRepository()
        let project = ProjectFixture.make()
        repo.seed(project)
        let sut = FetchProjectUseCaseImpl(repository: repo)

        let result = try await sut.fetch(id: project.id)

        #expect(result == project)
        #expect(repo.fetchByIDCount == 1)
    }

    @Test("존재하지 않는 id로 조회하면 nil을 반환한다")
    func fetchByIDReturnsNilForMissing() async throws {
        let sut = FetchProjectUseCaseImpl(repository: InMemoryProjectRepository())

        let result = try await sut.fetch(id: UUID())

        #expect(result == nil)
    }

    @Test("Repository.fetch 실패는 repositoryFailure로 매핑된다")
    func fetchByIDMapsRepositoryFailure() async {
        let repo = InMemoryProjectRepository()
        repo.errorOnFetchByID = .storageUnavailable
        let sut = FetchProjectUseCaseImpl(repository: repo)

        await #expect(throws: ProjectUseCaseError.repositoryFailure(.storageUnavailable)) {
            _ = try await sut.fetch(id: UUID())
        }
    }

    // MARK: - fetchAll()

    @Test("fetchAll은 저장된 모든 Project를 반환한다")
    func fetchAllReturnsAllProjects() async throws {
        let repo = InMemoryProjectRepository()
        let project1 = ProjectFixture.make(id: UUID(), name: "Project A")
        let project2 = ProjectFixture.make(id: UUID(), name: "Project B")
        repo.seed(project1)
        repo.seed(project2)
        let sut = FetchProjectUseCaseImpl(repository: repo)

        let result = try await sut.fetchAll()

        #expect(Set(result.map(\.id)) == [project1.id, project2.id])
        #expect(repo.fetchAllCount == 1)
    }

    @Test("저장된 Project가 없으면 빈 배열을 반환한다")
    func fetchAllReturnsEmptyWhenNone() async throws {
        let sut = FetchProjectUseCaseImpl(repository: InMemoryProjectRepository())

        let result = try await sut.fetchAll()

        #expect(result.isEmpty)
    }

    @Test("Repository.fetchAll 실패는 repositoryFailure로 매핑된다")
    func fetchAllMapsRepositoryFailure() async {
        let repo = InMemoryProjectRepository()
        repo.errorOnFetchAll = .storageUnavailable
        let sut = FetchProjectUseCaseImpl(repository: repo)

        await #expect(throws: ProjectUseCaseError.repositoryFailure(.storageUnavailable)) {
            _ = try await sut.fetchAll()
        }
    }
}
