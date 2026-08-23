// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct CreateSecretUseCaseImpl: CreateSecretUseCase {
    private let repository: any SecretRepository
    private let cryptoService: any SecretCryptoService
    private let entitlementUseCase: any EntitlementUseCase
    private let idGenerator: @Sendable () -> UUID
    private let dateProvider: @Sendable () -> Date

    /// - Parameters:
    ///   - repository: Secret 저장소
    ///   - cryptoService: payload 암호화·metadata 인코딩
    ///   - entitlementUseCase: 무료 티어 한도 판정. **기본값을 두지 않는다** — 빠뜨리면 가드가 조용히 사라진다
    ///   - idGenerator: 새 Secret의 ID
    ///   - dateProvider: 생성·수정 시각
    public init(
        repository: any SecretRepository,
        cryptoService: any SecretCryptoService,
        entitlementUseCase: any EntitlementUseCase,
        idGenerator: @escaping @Sendable () -> UUID = { UUID() },
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.cryptoService = cryptoService
        self.entitlementUseCase = entitlementUseCase
        self.idGenerator = idGenerator
        self.dateProvider = dateProvider
    }

    /// 무료 티어 한도에 걸리면 생성을 막는다. **암호화보다 앞에 둔다** — 거부될 생성에 크립토 작업을 들일 이유가 없다.
    ///
    /// 판정 실패(저장소 오류)와 게이트 차단은 다른 것이다. 전자는 ``SecretUseCaseError``로 매핑하고, 후자만 ``EntitlementError``로 내보내 호출부가 페이월을 띄우게 한다.
    private func ensureCreatable() async throws {
        let allowed: Bool
        do {
            allowed = try await entitlementUseCase.canCreateSecret()
        } catch {
            throw SecretUseCaseError.map(error)
        }
        guard allowed else { throw EntitlementError.limitReached }
    }

    public func execute<Payload: SecretPayloadData>(
        draft: SecretDraft,
        payload: Payload,
        projectIDs: [UUID]
    ) async throws -> Secret {
        try await ensureCreatable()

        do {
            let draft = try SecretUseCaseHelper.normalizedDraft(draft)
            let now = dateProvider()
            let encryptedPayload = try await cryptoService.encryptPayload(payload)
            let secret = Secret(
                id: idGenerator(),
                name: draft.name,
                secretType: draft.secretType,
                subType: draft.subType,
                service: draft.service,
                environment: draft.environment,
                expiresAt: draft.expiresAt,
                memo: draft.memo,
                liked: draft.liked,
                createdAt: now,
                updatedAt: now,
                payload: encryptedPayload
            )
            return try await repository.create(secret, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func execute<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        draft: SecretDraft,
        payload: Payload,
        metadata: Metadata,
        projectIDs: [UUID]
    ) async throws -> Secret {
        try await ensureCreatable()

        do {
            let draft = try SecretUseCaseHelper.normalizedDraft(draft)
            let now = dateProvider()
            let encryptedPayload = try await cryptoService.encryptPayload(payload)
            let encodedMetadata = try cryptoService.encodeMetadata(metadata)
            let secret = Secret(
                id: idGenerator(),
                name: draft.name,
                secretType: draft.secretType,
                subType: draft.subType,
                service: draft.service,
                environment: draft.environment,
                expiresAt: draft.expiresAt,
                memo: draft.memo,
                liked: draft.liked,
                createdAt: now,
                updatedAt: now,
                payload: encryptedPayload,
                metadata: encodedMetadata
            )
            return try await repository.create(secret, projectIDs: projectIDs)
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
