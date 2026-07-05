// Copyright © 2026 Devault. All rights reserved

import Foundation

@testable import DVDomain

/// 테스트용 SecretCryptoService 구현. 실제 암호화 대신 JSON 인코딩을 그대로 사용한다.
public final class FakeSecretCryptoService: SecretCryptoService, @unchecked Sendable {
    public var keyTag: String = "fake-key-tag"

    public var errorOnEncryptPayload: SecretCryptoError?
    public var errorOnDecryptPayload: SecretCryptoError?
    public var errorOnEncodeMetadata: SecretCryptoError?
    public var errorOnDecodeMetadata: SecretCryptoError?

    public private(set) var encryptCount = 0
    public private(set) var decryptCount = 0
    public private(set) var encodeCount = 0
    public private(set) var decodeCount = 0

    public init() {}

    public func encryptPayload<Payload: SecretPayloadData>(_ payload: Payload) async throws -> SecretPayload {
        encryptCount += 1
        if let error = errorOnEncryptPayload { throw error }
        let data = try JSONEncoder().encode(payload)
        return SecretPayload(
            encryptedData: data,
            keyTag: keyTag,
            schemaVersion: Payload.schemaVersion
        )
    }

    public func decryptPayload<Payload: SecretPayloadData>(
        _ payload: SecretPayload,
        as type: Payload.Type
    ) async throws -> Payload {
        decryptCount += 1
        if let error = errorOnDecryptPayload { throw error }
        return try JSONDecoder().decode(Payload.self, from: payload.encryptedData)
    }

    public func encodeMetadata<Metadata: SecretMetadataContent>(_ metadata: Metadata) throws -> SecretMetadata {
        encodeCount += 1
        if let error = errorOnEncodeMetadata { throw error }
        let data = try JSONEncoder().encode(metadata)
        return SecretMetadata(metadataJSON: data, schemaVersion: Metadata.schemaVersion)
    }

    public func decodeMetadata<Metadata: SecretMetadataContent>(
        _ metadata: SecretMetadata,
        as type: Metadata.Type
    ) throws -> Metadata {
        decodeCount += 1
        if let error = errorOnDecodeMetadata { throw error }
        return try JSONDecoder().decode(Metadata.self, from: metadata.metadataJSON)
    }
}
