// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol PatchSecretUseCase: Sendable {
    /// SecretPatch를 그대로 적용한다. liked 토글·soft delete 등 단순 필드 수정에 사용한다.
    /// updatedAt이 미지정이면 현재 시각으로 자동 세팅된다.
    /// - Parameters:
    ///   - id: 수정할 Secret의 ID
    ///   - patch: 변경할 필드만 담은 SecretPatch
    /// - Returns: 수정된 Secret
    func patch(id: UUID, with patch: SecretPatch) async throws -> Secret

    /// Secret의 모든 필드와 Project 연결을 한 번에 수정한다.
    /// payload는 내부에서 암호화되며, projectIDs를 기준으로 연결 상태를 재조정한다.
    /// - Parameters:
    ///   - id: 수정할 Secret의 ID
    ///   - patch: 일반 필드 변경 정보. payload·updatedAt은 이 메서드가 직접 세팅하므로 미지정으로 전달
    ///   - payload: 암호화할 Secret 값
    ///   - projectIDs: 수정 후 연결되어야 할 Project ID 목록
    /// - Returns: 수정된 Secret
    func update<Payload: SecretPayloadData>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        projectIDs: [UUID]
    ) async throws -> Secret

    /// Secret의 모든 필드·metadata·Project 연결을 한 번에 수정한다.
    /// payload와 metadata는 내부에서 암호화/인코딩되며, projectIDs를 기준으로 연결 상태를 재조정한다.
    /// - Parameters:
    ///   - id: 수정할 Secret의 ID
    ///   - patch: 일반 필드 변경 정보. payload·metadata·updatedAt은 이 메서드가 직접 세팅하므로 미지정으로 전달
    ///   - payload: 암호화할 Secret 값
    ///   - metadata: 인코딩할 부가 정보
    ///   - projectIDs: 수정 후 연결되어야 할 Project ID 목록
    /// - Returns: 수정된 Secret
    func update<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        id: UUID,
        patch: SecretPatch,
        payload: Payload,
        metadata: Metadata,
        projectIDs: [UUID]
    ) async throws -> Secret
}
