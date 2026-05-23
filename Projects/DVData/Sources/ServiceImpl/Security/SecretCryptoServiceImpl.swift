// Copyright © 2026 Devault. All rights reserved

import CryptoKit
import DVDomain
import Foundation

public struct SecretCryptoServiceImpl: SecretCryptoService {
    private let masterKeyTag: String
    private let keyStore: KeychainKeyStore
    private let payloadJSONCoder: SecretPayloadJSONCoder
    private let metadataJSONCoder: SecretMetadataJSONCoder

    /// Keychain key tag와 service namespace를 설정해 SecretCryptoService 구현체를 생성한다.
    public init(
        masterKeyTag: String = "com.devault.masterKey.v1",
        keychainService: String = "com.devault.secret"
    ) {
        self.masterKeyTag = masterKeyTag
        self.keyStore = KeychainKeyStore(service: keychainService)
        self.payloadJSONCoder = SecretPayloadJSONCoder()
        self.metadataJSONCoder = SecretMetadataJSONCoder()
    }

    /// Payload content를 JSON으로 직렬화한 뒤 AES-GCM으로 암호화해 저장용 SecretPayload를 만든다.
    public func encryptPayload<Payload: SecretPayloadData>(
        _ payload: Payload
    ) async throws -> DVDomain.SecretPayload {
        do {
            let key = try keyStore.getOrCreateSymmetricKey(tag: masterKeyTag)
            let json = try payloadJSONCoder.encode(payload)
            // nonce + ciphertext + authentication tag 생성
            let sealedBox = try AES.GCM.seal(json, using: key)

            // 3가지를 하나의 Data로 합침 -> DB에 저장
            guard let combined = sealedBox.combined else {
                throw SecretCryptoError.encryptionFailed
            }

            return DVDomain.SecretPayload(
                encryptedData: combined,
                keyTag: masterKeyTag,
                schemaVersion: Payload.schemaVersion
            )
        } catch let error as SecretCryptoError {
            throw error
        } catch {
            throw SecretCryptoError.encryptionFailed
        }
    }

    /// 저장된 SecretPayload를 keyTag로 복호화한 뒤 요청한 payload content 타입으로 역직렬화한다.
    public func decryptPayload<Payload: SecretPayloadData>(
        _ payload: DVDomain.SecretPayload,
        as type: Payload.Type
    ) async throws -> Payload {
        do {
            // 새 key를 만들어도 기존 암호문은 열릴 수 없으므로 key가 없을 때 새 키를 만들지 않음
            let key = try keyStore.getSymmetricKey(tag: payload.keyTag)
            let sealedBox = try AES.GCM.SealedBox(combined: payload.encryptedData)
            // key가 맞는지, authentication tag가 유효한지 확인
            let json = try AES.GCM.open(sealedBox, using: key)
            return try payloadJSONCoder.decode(json, as: type)
        } catch let error as SecretCryptoError {
            throw error
        } catch {
            throw SecretCryptoError.decryptionFailed
        }
    }

    /// Metadata content를 JSON Data로 직렬화해 저장용 SecretMetadata를 만든다.
    public func encodeMetadata<Metadata: SecretMetadataContent>(
        _ metadata: Metadata
    ) throws -> DVDomain.SecretMetadata {
        let json = try metadataJSONCoder.encode(metadata)
        return DVDomain.SecretMetadata(
            metadataJSON: json,
            schemaVersion: Metadata.schemaVersion
        )
    }

    /// 저장된 SecretMetadata의 JSON Data를 요청한 metadata content 타입으로 역직렬화한다.
    public func decodeMetadata<Metadata: SecretMetadataContent>(
        _ metadata: DVDomain.SecretMetadata,
        as type: Metadata.Type
    ) throws -> Metadata {
        try metadataJSONCoder.decode(metadata.metadataJSON, as: type)
    }
}
