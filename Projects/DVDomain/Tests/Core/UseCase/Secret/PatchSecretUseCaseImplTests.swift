// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("PatchSecretUseCaseImpl")
struct PatchSecretUseCaseImplTests {
    // MARK: - updateSimple(id:with:)

    @Test("updateSimple은 updatedAt이 unchanged면 주입 시각으로 채운다")
    func updateSimpleFillsUpdatedAtWhenUnchanged() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let fixedNow = Date(timeIntervalSince1970: 1_900_000_000)
        let sut = PatchSecretUseCaseImpl(
            repository: repo,
            cryptoService: FakeSecretCryptoService(),
            dateProvider: { fixedNow }
        )

        _ = try await sut.updateSimple(id: secret.id, with: SecretPatch(liked: .set(true)))

        #expect(repo.lastPatch?.updatedAt == .set(fixedNow))
        #expect(repo.lastPatch?.liked == .set(true))
    }

    @Test("updateSimple은 updatedAt이 이미 set이면 그대로 유지한다")
    func updateSimplePreservesExplicitUpdatedAt() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let explicit = Date(timeIntervalSince1970: 1_950_000_000)
        let sut = PatchSecretUseCaseImpl(
            repository: repo,
            cryptoService: FakeSecretCryptoService(),
            dateProvider: { Date() }
        )

        _ = try await sut.updateSimple(
            id: secret.id,
            with: SecretPatch(liked: .set(true), updatedAt: .set(explicit))
        )

        #expect(repo.lastPatch?.updatedAt == .set(explicit))
    }

    @Test("존재하지 않는 id에 대한 updateSimple은 secretNotFound로 매핑된다")
    func updateSimpleMapsSecretNotFound() async {
        let repo = InMemorySecretRepository()
        let missingID = UUID()
        let sut = PatchSecretUseCaseImpl(
            repository: repo,
            cryptoService: FakeSecretCryptoService()
        )

        await #expect(throws: SecretUseCaseError.secretNotFound(id: missingID)) {
            _ = try await sut.updateSimple(id: missingID, with: SecretPatch(liked: .set(true)))
        }
    }

    // MARK: - update(id:patch:payload:projectIDs:)

    @Test("update는 payload를 암호화하고 updatedAt을 주입 시각으로 세팅한다")
    func updateEncryptsPayloadAndSetsUpdatedAt() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let crypto = FakeSecretCryptoService()
        let fixedNow = Date(timeIntervalSince1970: 1_900_000_000)
        let sut = PatchSecretUseCaseImpl(
            repository: repo,
            cryptoService: crypto,
            dateProvider: { fixedNow }
        )

        _ = try await sut.update(
            id: secret.id,
            patch: SecretPatch(name: .set("Renamed")),
            payload: APIKeyPayload(value: "sk_new"),
            projectIDs: .unchanged
        )

        #expect(crypto.encryptCount == 1)
        #expect(repo.lastPatch?.name == .set("Renamed"))
        #expect(repo.lastPatch?.updatedAt == .set(fixedNow))
        if case .set(let p) = repo.lastPatch?.payload {
            #expect(p.keyTag == crypto.keyTag)
        } else {
            Issue.record("payload가 set이어야 한다")
        }
    }

    @Test("update metadata 오버로드는 payload 암호화·metadata 인코딩·updatedAt 세팅을 모두 수행한다")
    func updateWithMetadata() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let crypto = FakeSecretCryptoService()
        let fixedNow = Date(timeIntervalSince1970: 1_900_000_000)
        let sut = PatchSecretUseCaseImpl(
            repository: repo,
            cryptoService: crypto,
            dateProvider: { fixedNow }
        )

        _ = try await sut.update(
            id: secret.id,
            patch: SecretPatch(),
            payload: APIKeyPayload(value: "sk"),
            metadata: APIKeyMetadata(scope: "read"),
            projectIDs: .unchanged
        )

        #expect(crypto.encryptCount == 1)
        #expect(crypto.encodeCount == 1)
        #expect(repo.lastPatch?.updatedAt == .set(fixedNow))
        if case .set(let m) = repo.lastPatch?.metadata {
            #expect(m != nil)
        } else {
            Issue.record("metadata가 set이어야 한다")
        }
    }

    @Test("update의 암호화 실패는 cryptoFailure로 매핑되고 Repository patch는 호출되지 않는다")
    func updateMapsEncryptionFailure() async {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let crypto = FakeSecretCryptoService()
        crypto.errorOnEncryptPayload = .encryptionFailed
        let sut = PatchSecretUseCaseImpl(repository: repo, cryptoService: crypto)

        await #expect(throws: SecretUseCaseError.cryptoFailure(.encryptionFailed)) {
            _ = try await sut.update(
                id: secret.id,
                patch: SecretPatch(),
                payload: APIKeyPayload(value: "sk"),
                projectIDs: .unchanged
            )
        }
        #expect(repo.patchCount == 0)
        #expect(repo.patchWithProjectsCount == 0)
    }

    // MARK: - update(id:patch:metadata:projectIDs:)

    @Test("metadata-only update는 payload 암호화 없이 metadata 인코딩만 수행한다")
    func updateMetadataOnlyEncodesMetadata() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let crypto = FakeSecretCryptoService()
        let sut = PatchSecretUseCaseImpl(repository: repo, cryptoService: crypto)

        _ = try await sut.update(
            id: secret.id,
            patch: SecretPatch(),
            metadata: APIKeyMetadata(scope: "read"),
            projectIDs: .unchanged
        )

        #expect(crypto.encryptCount == 0)
        #expect(crypto.encodeCount == 1)
        if case .set(let m) = repo.lastPatch?.metadata {
            #expect(m != nil)
        } else {
            Issue.record("metadata가 set이어야 한다")
        }
    }

    // MARK: - projectIDs 라우팅

    @Test("projectIDs가 .unchanged면 patch(id:with:)를 호출한다")
    func updateWithUnchangedProjectIDsCallsPatchWithoutProjects() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let sut = PatchSecretUseCaseImpl(repository: repo, cryptoService: FakeSecretCryptoService())

        _ = try await sut.update(id: secret.id, patch: SecretPatch(liked: .set(true)), projectIDs: .unchanged)

        #expect(repo.patchCount == 1)
        #expect(repo.patchWithProjectsCount == 0)
    }

    @Test("projectIDs가 .set이면 patch(id:with:projectIDs:)를 호출하고 lastProjectIDs를 전달한다")
    func updateWithSetProjectIDsCallsPatchWithProjects() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let projectID = UUID()
        let sut = PatchSecretUseCaseImpl(repository: repo, cryptoService: FakeSecretCryptoService())

        _ = try await sut.update(id: secret.id, patch: SecretPatch(), projectIDs: .set([projectID]))

        #expect(repo.patchWithProjectsCount == 1)
        #expect(repo.patchCount == 0)
        #expect(repo.lastProjectIDs == [projectID])
    }
}
