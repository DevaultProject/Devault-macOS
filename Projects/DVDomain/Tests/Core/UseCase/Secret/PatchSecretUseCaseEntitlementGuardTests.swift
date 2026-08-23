// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

/// 한도 초과 보유 시 수정 잠금(설계 §5)의 도메인 방어선을 검증한다.
///
/// 화면 쪽은 `didTapEdit`에서 이미 걸러지므로, 여기서 막는 것은 **UI를 우회한 호출**이다.
@Suite("PatchSecretUseCaseImpl 수정 잠금")
struct PatchSecretUseCaseEntitlementGuardTests {

    private func makeSUT(
        canEditSecrets: Bool
    ) -> (PatchSecretUseCaseImpl, InMemorySecretRepository, StubEntitlementUseCase, Secret) {
        let repo = InMemorySecretRepository()
        let secret = SecretFixture.make()
        repo.seed(secret)
        let entitlement = StubEntitlementUseCase(canEditSecrets: canEditSecrets)
        let sut = PatchSecretUseCaseImpl(
            repository: repo,
            cryptoService: FakeSecretCryptoService(),
            entitlementUseCase: entitlement
        )
        return (sut, repo, entitlement, secret)
    }

    // MARK: - 잠긴 상태에서 차단되는 것

    @Test("잠기면 이름 변경이 차단된다")
    func blocksNameChangeWhenLocked() async throws {
        let (sut, _, _, secret) = makeSUT(canEditSecrets: false)

        await #expect(throws: SecretUseCaseError.editLockedByEntitlement) {
            _ = try await sut.updateSimple(id: secret.id, with: SecretPatch(name: .set("새 이름")))
        }
    }

    @Test("잠기면 만료일 변경이 차단된다")
    func blocksExpiresAtChangeWhenLocked() async throws {
        let (sut, _, _, secret) = makeSUT(canEditSecrets: false)

        await #expect(throws: SecretUseCaseError.editLockedByEntitlement) {
            _ = try await sut.updateSimple(id: secret.id, with: SecretPatch(expiresAt: .set(Date())))
        }
    }

    @Test("잠기면 payload 변경이 차단된다")
    func blocksPayloadChangeWhenLocked() async throws {
        let (sut, _, _, secret) = makeSUT(canEditSecrets: false)

        await #expect(throws: SecretUseCaseError.editLockedByEntitlement) {
            _ = try await sut.update(
                id: secret.id,
                patch: SecretPatch(),
                payload: APIKeyPayload(value: "sk_test"),
                projectIDs: .unchanged
            )
        }
    }

    @Test("잠기면 프로젝트 이동이 차단된다")
    func blocksProjectChangeWhenLocked() async throws {
        let (sut, _, _, secret) = makeSUT(canEditSecrets: false)

        await #expect(throws: SecretUseCaseError.editLockedByEntitlement) {
            _ = try await sut.update(id: secret.id, patch: SecretPatch(), projectIDs: .set([UUID()]))
        }
    }

    // MARK: - 잠긴 상태에서도 허용되는 것

    @Test("잠겨도 즐겨찾기 토글은 통과한다")
    func allowsLikeToggleWhenLocked() async throws {
        let (sut, _, _, secret) = makeSUT(canEditSecrets: false)

        let updated = try await sut.updateSimple(id: secret.id, with: SecretPatch(liked: .set(true)))

        #expect(updated.liked == true)
    }

    @Test("잠겨도 휴지통 이동·복원은 통과한다")
    func allowsTrashChangeWhenLocked() async throws {
        let (sut, _, _, secret) = makeSUT(canEditSecrets: false)
        let deletedAt = Date(timeIntervalSince1970: 1_900_000_000)

        let deleted = try await sut.updateSimple(id: secret.id, with: SecretPatch(deletedAt: .set(deletedAt)))
        #expect(deleted.deletedAt == deletedAt)

        let restored = try await sut.updateSimple(id: secret.id, with: SecretPatch(deletedAt: .set(nil)))
        #expect(restored.deletedAt == nil)
    }

    @Test("허용된 변경은 판정을 아예 묻지 않는다 — 즐겨찾기마다 카운트 쿼리가 나가면 안 된다")
    func skipsJudgementForAllowedChange() async throws {
        let (sut, _, entitlement, secret) = makeSUT(canEditSecrets: false)

        _ = try await sut.updateSimple(id: secret.id, with: SecretPatch(liked: .set(true)))

        #expect(entitlement.canEditSecretsCallCount == 0)
    }

    @Test("즐겨찾기와 이름을 함께 바꾸면 차단된다 — 허용 필드에 묻어 갈 수 없다")
    func blocksAllowedFieldMixedWithDisallowed() async throws {
        let (sut, _, _, secret) = makeSUT(canEditSecrets: false)

        await #expect(throws: SecretUseCaseError.editLockedByEntitlement) {
            _ = try await sut.updateSimple(
                id: secret.id,
                with: SecretPatch(name: .set("새 이름"), liked: .set(true))
            )
        }
    }

    // MARK: - 잠기지 않은 상태

    @Test("잠기지 않으면 이름 변경이 통과한다")
    func allowsNameChangeWhenUnlocked() async throws {
        let (sut, _, entitlement, secret) = makeSUT(canEditSecrets: true)

        let updated = try await sut.updateSimple(id: secret.id, with: SecretPatch(name: .set("새 이름")))

        #expect(updated.name == "새 이름")
        #expect(entitlement.canEditSecretsCallCount == 1)
    }
}
