// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation

struct SecretMetadataJSONCoder: Sendable {
    /// Metadata content를 JSON Data로 직렬화한다.
    func encode<Metadata: SecretMetadataContent>(_ metadata: Metadata) throws -> Data {
        do {
            return try JSONEncoder().encode(metadata)
        } catch {
            throw SecretCryptoError.encodingFailed
        }
    }

    /// JSON Data를 요청한 metadata content 타입으로 역직렬화한다.
    func decode<Metadata: SecretMetadataContent>(
        _ data: Data,
        as type: Metadata.Type
    ) throws -> Metadata {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw SecretCryptoError.decodingFailed
        }
    }
}
