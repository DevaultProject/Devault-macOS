// Copyright © 2026 Devault. All rights reserved

/// Secret payload 암호화와 metadata 인코딩을 수행하는 서비스 프로토콜입니다.
public protocol SecretCryptoService: Sendable {
    func encryptPayload<Payload: SecretPayloadData>(
        _ payload: Payload
    ) async throws -> SecretPayload

    func decryptPayload<Payload: SecretPayloadData>(
        _ payload: SecretPayload,
        as type: Payload.Type
    ) async throws -> Payload

    func encodeMetadata<Metadata: SecretMetadataContent>(
        _ metadata: Metadata
    ) throws -> SecretMetadata

    func decodeMetadata<Metadata: SecretMetadataContent>(
        _ metadata: SecretMetadata,
        as type: Metadata.Type
    ) throws -> Metadata
}
