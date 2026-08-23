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
            entitlementUseCase: StubEntitlementUseCase(),
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
            entitlementUseCase: StubEntitlementUseCase(),
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
            cryptoService: FakeSecretCryptoService(),
        entitlementUseCase: StubEntitlementUseCase()
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
            entitlementUseCase: StubEntitlementUseCase(),
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
            entitlementUseCase: StubEntitlementUseCase(),
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
        let sut = PatchSecretUseCaseImpl(repository: repo, cryptoService: crypto, entitlementUseCase: StubEntitlementUseCase())

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
        let sut = PatchSecretUseCaseImpl(repository: repo, cryptoService: crypto, entitlementUseCase: StubEntitlementUseCase())

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
        let sut = PatchSecretUseCaseImpl(repository: repo, cryptoService: FakeSecretCryptoService(), entitlementUseCase: StubEntitlementUseCase())

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
        let sut = PatchSecretUseCaseImpl(repository: repo, cryptoService: FakeSecretCryptoService(), entitlementUseCase: StubEntitlementUseCase())

        _ = try await sut.update(id: secret.id, patch: SecretPatch(), projectIDs: .set([projectID]))

        #expect(repo.patchWithProjectsCount == 1)
        #expect(repo.patchCount == 0)
        #expect(repo.lastProjectIDs == [projectID])
    }

    @Test("projectIDs가 .set일 때 존재하지 않는 id는 secretNotFound로 매핑된다")
    func updateWithSetProjectIDsMapsSecretNotFound() async {
        let missingID = UUID()
        let sut = PatchSecretUseCaseImpl(repository: InMemorySecretRepository(), cryptoService: FakeSecretCryptoService(), entitlementUseCase: StubEntitlementUseCase())

        await #expect(throws: SecretUseCaseError.secretNotFound(id: missingID)) {
            _ = try await sut.update(id: missingID, patch: SecretPatch(), projectIDs: .set([UUID()]))
        }
    }

    // MARK: - 정규화

    /// 네 overload 중 하나만 정규화를 빠뜨려도 그 경로로 저장한 시크릿의 만료 시각이 어긋난다.
    /// 한 곳에만 적용하고 나머지를 잊는 것이 이 종류 버그의 전형이라 전부를 한 테스트로 훑는다.
    @Test("네 overload 모두 expiresAt을 그 날 23:59:59로 고정한다")
    func allOverloadsAnchorExpiresAtToEndOfDay() async throws {
        let pickedDate = DateComponents(
            calendar: .current, year: 2026, month: 8, day: 20, hour: 9, minute: 30, second: 0
        ).date!
        let patch = SecretPatch(expiresAt: .set(pickedDate))

        let overloads: [(name: String, call: @Sendable (PatchSecretUseCaseImpl, UUID) async throws -> Void)] = [
            ("update(id:patch:projectIDs:)", { sut, id in
                _ = try await sut.update(id: id, patch: patch, projectIDs: .unchanged)
            }),
            ("update(id:patch:metadata:projectIDs:)", { sut, id in
                _ = try await sut.update(
                    id: id,
                    patch: patch,
                    metadata: APIKeyMetadata(scope: "read"),
                    projectIDs: .unchanged
                )
            }),
            ("update(id:patch:payload:projectIDs:)", { sut, id in
                _ = try await sut.update(
                    id: id,
                    patch: patch,
                    payload: APIKeyPayload(value: "sk"),
                    projectIDs: .unchanged
                )
            }),
            ("update(id:patch:payload:metadata:projectIDs:)", { sut, id in
                _ = try await sut.update(
                    id: id,
                    patch: patch,
                    payload: APIKeyPayload(value: "sk"),
                    metadata: APIKeyMetadata(scope: "read"),
                    projectIDs: .unchanged
                )
            }),
        ]

        for overload in overloads {
            let repo = InMemorySecretRepository()
            let secret = SecretFixture.make()
            repo.seed(secret)
            let sut = PatchSecretUseCaseImpl(repository: repo, cryptoService: FakeSecretCryptoService(), entitlementUseCase: StubEntitlementUseCase())

            try await overload.call(sut, secret.id)

            guard case .set(let anchored?) = repo.lastPatch?.expiresAt else {
                Issue.record("\(overload.name): expiresAt이 set이어야 한다")
                continue
            }
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: anchored
            )
            #expect(components.year == 2026, "\(overload.name)")
            #expect(components.month == 8, "\(overload.name)")
            #expect(components.day == 20, "\(overload.name)")
            #expect(components.hour == 23, "\(overload.name)")
            #expect(components.minute == 59, "\(overload.name)")
            #expect(components.second == 59, "\(overload.name)")
        }
    }

    @Test("공백만 있는 이름은 invalidName으로 거부되고 암호화·Repository 호출이 일어나지 않는다")
    func rejectsBlankNameBeforeEncrypting() async {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let crypto = FakeSecretCryptoService()
        let sut = PatchSecretUseCaseImpl(repository: repo, cryptoService: crypto, entitlementUseCase: StubEntitlementUseCase())

        await #expect(throws: SecretUseCaseError.invalidName) {
            _ = try await sut.update(
                id: secret.id,
                patch: SecretPatch(name: .set("  \n ")),
                payload: APIKeyPayload(value: "sk"),
                projectIDs: .unchanged
            )
        }
        // 정규화가 암호화보다 먼저 걸리는지 확인한다 — 거부될 patch에 크립토 작업이 들어가면 안 된다.
        #expect(crypto.encryptCount == 0)
        #expect(repo.patchCount == 0)
        #expect(repo.patchWithProjectsCount == 0)
    }

    @Test("만료일 삭제 요청(.set(nil))은 그대로 Repository에 전달된다")
    func forwardsExpiresAtClearRequest() async throws {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make(expiresAt: Date(timeIntervalSince1970: 1_800_000_000))
        repo.seed(secret)
        let sut = PatchSecretUseCaseImpl(repository: repo, cryptoService: FakeSecretCryptoService(), entitlementUseCase: StubEntitlementUseCase())

        let updated = try await sut.update(
            id: secret.id,
            patch: SecretPatch(expiresAt: .set(nil)),
            projectIDs: .unchanged
        )

        #expect(repo.lastPatch?.expiresAt == .set(nil))
        #expect(updated.expiresAt == nil)
    }
}
