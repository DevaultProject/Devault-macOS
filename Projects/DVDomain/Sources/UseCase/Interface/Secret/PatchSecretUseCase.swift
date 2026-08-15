// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 이미 저장된 Secret의 일부를 변경합니다.
///
/// 네 overload 모두 `patch`를 저장 전에 정규화합니다 — `name`은 앞뒤 공백이 제거되고(공백만 남으면
/// ``SecretUseCaseError/invalidName``), `expiresAt`은 그 날의 23:59:59로 고정됩니다. 생성 경로가
/// 적용하는 규칙과 같습니다. `.unchanged`인 필드는 건드리지 않고, `expiresAt`의 `.set(nil)`은
/// 만료일을 지우는 요청이므로 그대로 전달됩니다.
public protocol PatchSecretUseCase: Sendable {
    /// payload·metadata 변경 없이 일반 필드와 Project 연결만 수정한다.
    /// payload 복호화가 발생하지 않으므로 생체인증 없이 호출 가능하다.
    /// updatedAt은 이 메서드가 직접 세팅한다.
    /// - Parameters:
    ///   - id: 수정할 Secret의 ID
    ///   - patch: 일반 필드 변경 정보. updatedAt은 이 메서드가 직접 세팅하므로 미지정으로 전달
    ///   - projectIDs: .unchanged면 연결 상태 유지, .set([])이면 전체 unlink, .set([...])이면 해당 목록으로 재조정
    /// - Returns: 수정된 Secret
    func update(
        id: UUID,
        patch: SecretPatch,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret

    /// payload 변경 없이 metadata와 일반 필드·Project 연결을 수정한다.
    /// payload 복호화가 발생하지 않으므로 생체인증 없이 호출 가능하다.
    /// metadata는 내부에서 인코딩되며, updatedAt은 이 메서드가 직접 세팅한다.
    /// - Parameters:
    ///   - id: 수정할 Secret의 ID
    ///   - patch: 일반 필드 변경 정보. metadata·updatedAt은 이 메서드가 직접 세팅하므로 미지정으로 전달
    ///   - metadata: 인코딩할 부가 정보
    ///   - projectIDs: .unchanged면 연결 상태 유지, .set([])이면 전체 unlink, .set([...])이면 해당 목록으로 재조정
    /// - Returns: 수정된 Secret
    func update<Metadata: SecretMetadataContent>(
        id: UUID,
        patch: SecretPatch,
        metadata: Metadata,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret

    /// Secret의 모든 필드와 Project 연결을 한 번에 수정한다.
    /// payload는 내부에서 암호화되며, projectIDs가 .set일 때만 연결 상태를 재조정한다.
    /// - Parameters:
    ///   - id: 수정할 Secret의 ID
    ///   - patch: 일반 필드 변경 정보. payload·updatedAt은 이 메서드가 직접 세팅하므로 미지정으로 전달
    ///   - payload: 암호화할 Secret 값
    ///   - projectIDs: .unchanged면 연결 상태 유지, .set([])이면 전체 unlink, .set([...])이면 해당 목록으로 재조정
    /// - Returns: 수정된 Secret
    func update<Payload: SecretPayloadData>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret

    /// Secret의 모든 필드·metadata·Project 연결을 한 번에 수정한다.
    /// payload와 metadata는 내부에서 암호화/인코딩되며, projectIDs가 .set일 때만 연결 상태를 재조정한다.
    /// - Parameters:
    ///   - id: 수정할 Secret의 ID
    ///   - patch: 일반 필드 변경 정보. payload·metadata·updatedAt은 이 메서드가 직접 세팅하므로 미지정으로 전달
    ///   - payload: 암호화할 Secret 값
    ///   - metadata: 인코딩할 부가 정보
    ///   - projectIDs: .unchanged면 연결 상태 유지, .set([])이면 전체 unlink, .set([...])이면 해당 목록으로 재조정
    /// - Returns: 수정된 Secret
    func update<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        metadata: Metadata,
        projectIDs: PatchField<[UUID]>
    ) async throws -> Secret
}

extension PatchSecretUseCase {
    /// `update(id:patch:projectIDs: .unchanged)`의 편의 메서드.
    /// liked 토글, metadata 제거 등 Project 연결 변경이 없는 단순 필드 수정에 사용한다.
    public func updateSimple(id: UUID, with patch: SecretPatch) async throws -> Secret {
        try await update(id: id, patch: patch, projectIDs: .unchanged)
    }
}
