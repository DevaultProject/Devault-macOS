// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("CreateProjectUseCaseImpl")
struct CreateProjectUseCaseImplTests {
    @Test("정상 이름을 넣으면 trimming되고 주입한 id/date로 저장된다")
    func executeHappyPath() async throws {
        let repo = InMemoryProjectRepository()
        let fixedID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
        let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)
        let sut = CreateProjectUseCaseImpl(
            repository: repo,
            idGenerator: { fixedID },
            dateProvider: { fixedDate }
        )

        let project = try await sut.execute(name: "  My Project  ")

        #expect(project.id == fixedID)
        #expect(project.name == "My Project")
        #expect(project.createdAt == fixedDate)
        #expect(project.updatedAt == fixedDate)
        #expect(repo.createCount == 1)
    }

    @Test("빈 이름은 invalidName 에러를 던진다")
    func executeRejectsEmptyName() async {
        let sut = CreateProjectUseCaseImpl(repository: InMemoryProjectRepository())

        await #expect(throws: ProjectUseCaseError.invalidName) {
            _ = try await sut.execute(name: "")
        }
    }

    @Test("공백만 있는 이름은 invalidName 에러를 던진다")
    func executeRejectsWhitespaceName() async {
        let sut = CreateProjectUseCaseImpl(repository: InMemoryProjectRepository())

        await #expect(throws: ProjectUseCaseError.invalidName) {
            _ = try await sut.execute(name: "   ")
        }
    }

    @Test("Repository.create 실패는 repositoryFailure로 매핑된다")
    func executeMapsRepositoryFailure() async {
        let existingID = UUID()
        let repo = InMemoryProjectRepository()
        repo.seed(ProjectFixture.make(id: existingID))
        let sut = CreateProjectUseCaseImpl(
            repository: repo,
            idGenerator: { existingID }
        )

        await #expect(throws: ProjectUseCaseError.repositoryFailure(.duplicateID(id: existingID))) {
            _ = try await sut.execute(name: "My Project")
        }
    }
}
