// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("DeleteSecretUseCaseImpl")
struct DeleteSecretUseCaseImplTests {
    @Test("softDelete는 deletedAt과 updatedAt을 주입 시각으로 세팅한다")
    func softDeleteSetsDeletedAndUpdatedAt() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let fixedNow = Date(timeIntervalSince1970: 1_950_000_000)
        let sut = DeleteSecretUseCaseImpl(repository: repo, dateProvider: { fixedNow })

        _ = try await sut.softDelete(id: secret.id)

        #expect(repo.lastPatch?.deletedAt == .set(fixedNow))
        #expect(repo.lastPatch?.updatedAt == .set(fixedNow))
    }

    @Test("restore는 deletedAt을 nil로 만들고 updatedAt은 주입 시각으로 세팅한다")
    func restoreClearsDeletedAt() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let fixedNow = Date(timeIntervalSince1970: 1_950_000_000)
        let sut = DeleteSecretUseCaseImpl(repository: repo, dateProvider: { fixedNow })

        _ = try await sut.restore(id: secret.id)

        #expect(repo.lastPatch?.deletedAt == .set(nil))
        #expect(repo.lastPatch?.updatedAt == .set(fixedNow))
    }

    @Test("permanentlyDelete는 Repository의 delete를 호출한다")
    func permanentlyDeleteCallsRepositoryDelete() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let sut = DeleteSecretUseCaseImpl(repository: repo)

        try await sut.permanentlyDelete(id: secret.id)

        #expect(repo.deleteCount == 1)
        #expect(repo.secrets[secret.id] == nil)
    }

    @Test("존재하지 않는 id에 대한 softDelete는 secretNotFound로 매핑된다")
    func softDeleteMapsSecretNotFound() async {
        let repo = InMemorySecretRepository()
        let missingID = UUID()
        let sut = DeleteSecretUseCaseImpl(repository: repo)

        await #expect(throws: SecretUseCaseError.secretNotFound(id: missingID)) {
            _ = try await sut.softDelete(id: missingID)
        }
    }

    @Test("존재하지 않는 id에 대한 permanentlyDelete는 secretNotFound로 매핑된다")
    func permanentlyDeleteMapsSecretNotFound() async {
        let repo = InMemorySecretRepository()
        let missingID = UUID()
        let sut = DeleteSecretUseCaseImpl(repository: repo)

        await #expect(throws: SecretUseCaseError.secretNotFound(id: missingID)) {
            try await sut.permanentlyDelete(id: missingID)
        }
    }
}
