// Copyright © 2026 Devault. All rights reserved

/// Secret payload 암호화와 metadata 인코딩을 수행하는 서비스 프로토콜입니다.
public protocol SecretCryptoService: Sendable {
    /// payload를 암호화해 저장 가능한 SecretPayload로 변환한다.
    /// - Parameter payload: 암호화할 원본 payload
    /// - Returns: 암호화된 SecretPayload
    func encryptPayload<Payload: SecretPayloadData>(
        _ payload: Payload
    ) async throws -> SecretPayload

    /// 암호화된 SecretPayload를 복호화해 원본 타입으로 변환한다.
    /// - Parameters:
    ///   - payload: 복호화할 SecretPayload
    ///   - type: 복호화 결과로 변환할 타입
    /// - Returns: 복호화된 payload
    func decryptPayload<Payload: SecretPayloadData>(
        _ payload: SecretPayload,
        as type: Payload.Type
    ) async throws -> Payload

    /// metadata를 인코딩해 저장 가능한 SecretMetadata로 변환한다.
    /// - Parameter metadata: 인코딩할 원본 metadata
    /// - Returns: 인코딩된 SecretMetadata
    func encodeMetadata<Metadata: SecretMetadataContent>(
        _ metadata: Metadata
    ) throws -> SecretMetadata

    /// 인코딩된 SecretMetadata를 원본 타입으로 복원한다.
    /// - Parameters:
    ///   - metadata: 복원할 SecretMetadata
    ///   - type: 복원 결과로 변환할 타입
    /// - Returns: 복원된 metadata
    func decodeMetadata<Metadata: SecretMetadataContent>(
        _ metadata: SecretMetadata,
        as type: Metadata.Type
    ) throws -> Metadata
}
