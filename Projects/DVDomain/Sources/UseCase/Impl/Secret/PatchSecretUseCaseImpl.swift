// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct PatchSecretUseCaseImpl: PatchSecretUseCase {
    private let repository: any SecretRepository
    private let cryptoService: any SecretCryptoService
    private let entitlementUseCase: any EntitlementUseCase
    private let dateProvider: @Sendable () -> Date

    /// - Parameters:
    ///   - repository: Secret 저장소
    ///   - cryptoService: payload 암호화·metadata 인코딩
    ///   - entitlementUseCase: 한도 초과 수정 잠금 판정. **기본값을 두지 않는다** — 빠뜨리면 가드가 조용히 사라진다
    ///   - dateProvider: `updatedAt`에 쓸 현재 시각
    public init(
        repository: any SecretRepository,
        cryptoService: any SecretCryptoService,
        entitlementUseCase: any EntitlementUseCase,
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.cryptoService = cryptoService
        self.entitlementUseCase = entitlementUseCase
        self.dateProvider = dateProvider
    }

    public func update(
        id: UUID,
        patch: SecretPatch,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret {
        do {
            var fullPatch = try SecretUseCaseHelper.normalizedPatch(patch)
            fullPatch = SecretUseCaseHelper.settingUpdatedAtIfNeeded(fullPatch, now: dateProvider())
            return try await applyPatch(id: id, patch: fullPatch, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func update<Metadata: SecretMetadataContent>(
        id: UUID,
        patch: SecretPatch,
        metadata: Metadata,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret {
        do {
            // 정규화를 인코딩·암호화보다 먼저 한다 — 거부될 patch에 크립토 작업을 들일 이유가 없다.
            var fullPatch = try SecretUseCaseHelper.normalizedPatch(patch)
            let encodedMetadata = try cryptoService.encodeMetadata(metadata)
            fullPatch.metadata = .set(encodedMetadata)
            fullPatch = SecretUseCaseHelper.settingUpdatedAtIfNeeded(fullPatch, now: dateProvider())
            return try await applyPatch(id: id, patch: fullPatch, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func update<Payload: SecretPayloadData>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret {
        do {
            var fullPatch = try SecretUseCaseHelper.normalizedPatch(patch)
            let encryptedPayload = try await cryptoService.encryptPayload(payload)
            fullPatch.payload = .set(encryptedPayload)
            fullPatch = SecretUseCaseHelper.settingUpdatedAtIfNeeded(fullPatch, now: dateProvider())
            return try await applyPatch(id: id, patch: fullPatch, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func update<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        metadata: Metadata,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret {
        do {
            var fullPatch = try SecretUseCaseHelper.normalizedPatch(patch)
            let encryptedPayload = try await cryptoService.encryptPayload(payload)
            let encodedMetadata = try cryptoService.encodeMetadata(metadata)
            fullPatch.payload = .set(encryptedPayload)
            fullPatch.metadata = .set(encodedMetadata)
            fullPatch = SecretUseCaseHelper.settingUpdatedAtIfNeeded(fullPatch, now: dateProvider())
            return try await applyPatch(id: id, patch: fullPatch, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}

extension PatchSecretUseCaseImpl {
    private func applyPatch(id: UUID, patch: SecretPatch, projectIDs: PatchField<[UUID]>) async throws -> Secret {
        try await ensureEditable(patch: patch, projectIDs: projectIDs)

        if case .set(let ids) = projectIDs {
            return try await repository.patch(id: id, with: patch, projectIDs: ids)
        }
        return try await repository.patch(id: id, with: patch)
    }

    /// 보유 수가 한도를 넘겼으면 수정을 막는다. **UI를 우회한 호출을 막는 마지막 방어선이다** — 화면 쪽은 `didTapEdit`에서 이미 걸러진다.
    ///
    /// 잠금과 무관한 변경은 판정 자체를 건너뛴다. `canEditSecrets()`가 저장소 개수를 세므로, 즐겨찾기를 누를 때마다 카운트 쿼리가 나가면 안 된다.
    private func ensureEditable(patch: SecretPatch, projectIDs: PatchField<[UUID]>) async throws {
        guard !isAllowedWhileLocked(patch, projectIDs: projectIDs) else { return }
        guard try await entitlementUseCase.canEditSecrets() else {
            throw SecretUseCaseError.editLockedByEntitlement
        }
    }

    /// 잠금 상태에서도 허용되는 변경인지 판정한다. 즐겨찾기와 휴지통 이동만 해당한다.
    ///
    /// 허용 필드를 걷어낸 나머지가 빈 patch와 같아야 한다. 필드를 하나씩 나열해 비교하지 않는 이유는, **나중에 `SecretPatch`에 필드가 추가돼도 기본이 차단**이어야 하기 때문이다. 나열식은 새 필드를 조용히 통과시킨다.
    ///
    /// `updatedAt`은 네 overload가 모두 세우므로 판단에서 제외한다.
    /// - Returns: 잠금과 무관한 변경이면 true
    private func isAllowedWhileLocked(_ patch: SecretPatch, projectIDs: PatchField<[UUID]>) -> Bool {
        guard case .unchanged = projectIDs else { return false }

        var rest = patch
        rest.liked = .unchanged
        rest.deletedAt = .unchanged
        rest.updatedAt = .unchanged
        return rest == SecretPatch()
    }
}
