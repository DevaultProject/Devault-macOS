// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol CreateSecretUseCase: Sendable {
    /// Secret을 생성하고 지정한 Project에 연결한다.
    /// payload는 내부에서 암호화된다. link 실패 시 생성된 Secret을 rollback한다.
    /// - Parameters:
    ///   - draft: 이름·타입 등 Secret의 기본 정보
    ///   - payload: 암호화할 Secret 값
    ///   - projectIDs: 생성 후 연결할 Project ID 목록. 빈 배열이면 연결 없이 생성
    /// - Returns: 생성된 Secret
    func execute<Payload: SecretPayloadData>(
        draft: SecretDraft,
        payload: Payload,
        projectIDs: [UUID]
    ) async throws -> Secret

    /// Secret을 생성하고 metadata를 포함해 지정한 Project에 연결한다.
    /// payload와 metadata는 내부에서 암호화/인코딩된다. link 실패 시 생성된 Secret을 rollback한다.
    /// - Parameters:
    ///   - draft: 이름·타입 등 Secret의 기본 정보
    ///   - payload: 암호화할 Secret 값
    ///   - metadata: 인코딩할 부가 정보
    ///   - projectIDs: 생성 후 연결할 Project ID 목록. 빈 배열이면 연결 없이 생성
    /// - Returns: 생성된 Secret
    func execute<Payload: SecretPayloadData, Metadata: SecretMetadataContent>(
        draft: SecretDraft,
        payload: Payload,
        metadata: Metadata,
        projectIDs: [UUID]
    ) async throws -> Secret
}
