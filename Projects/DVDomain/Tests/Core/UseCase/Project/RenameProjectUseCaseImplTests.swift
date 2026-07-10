// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("RenameProjectUseCaseImpl")
struct RenameProjectUseCaseImplTests {
    @Test("정상 이름을 넣으면 트리밍된 이름과 주입 시각으로 patch가 호출된다")
    func renameHappyPath() async throws {
        let repo = InMemoryProjectRepository()
        let project = ProjectFixture.make()
        repo.seed(project)
        let fixedNow = Date(timeIntervalSince1970: 1_900_000_000)
        let sut = RenameProjectUseCaseImpl(
            repository: repo,
            dateProvider: { fixedNow }
        )

        let renamed = try await sut.rename(id: project.id, name: "  Renamed  ")

        #expect(renamed.name == "Renamed")
        #expect(repo.patchCount == 1)
        #expect(repo.lastPatch?.name == .set("Renamed"))
        #expect(repo.lastPatch?.updatedAt == .set(fixedNow))
    }

    @Test("빈 이름은 invalidName 에러를 던진다")
    func renameRejectsEmptyName() async {
        let repo = InMemoryProjectRepository()
        repo.seed(ProjectFixture.make())
        let sut = RenameProjectUseCaseImpl(repository: repo)

        await #expect(throws: ProjectUseCaseError.invalidName) {
            _ = try await sut.rename(id: ProjectFixture.fixedID, name: "")
        }
    }

    @Test("공백만 있는 이름은 invalidName 에러를 던진다")
    func renameRejectsWhitespaceName() async {
        let repo = InMemoryProjectRepository()
        repo.seed(ProjectFixture.make())
        let sut = RenameProjectUseCaseImpl(repository: repo)

        await #expect(throws: ProjectUseCaseError.invalidName) {
            _ = try await sut.rename(id: ProjectFixture.fixedID, name: "   ")
        }
    }

    @Test("존재하지 않는 id는 projectNotFound로 매핑된다")
    func renameMapsNotFound() async {
        let missingID = UUID()
        let sut = RenameProjectUseCaseImpl(repository: InMemoryProjectRepository())

        await #expect(throws: ProjectUseCaseError.projectNotFound(id: missingID)) {
            _ = try await sut.rename(id: missingID, name: "New Name")
        }
    }

    @Test("Repository.patch 실패는 repositoryFailure로 매핑된다")
    func renameMapsRepositoryFailure() async {
        let repo = InMemoryProjectRepository()
        repo.seed(ProjectFixture.make())
        repo.errorOnPatch = .persistenceFailed
        let sut = RenameProjectUseCaseImpl(repository: repo)

        await #expect(throws: ProjectUseCaseError.repositoryFailure(.persistenceFailed)) {
            _ = try await sut.rename(id: ProjectFixture.fixedID, name: "New Name")
        }
    }
}
