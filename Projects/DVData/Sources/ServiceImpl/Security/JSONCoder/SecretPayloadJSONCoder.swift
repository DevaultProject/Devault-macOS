// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation

struct SecretPayloadJSONCoder: Sendable {
    /// Payload content를 JSON Data로 직렬화한다.
    func encode<Payload: SecretPayloadData>(_ payload: Payload) throws -> Data {
        do {
            return try JSONEncoder().encode(payload)
        } catch {
            throw SecretCryptoError.encodingFailed
        }
    }

    /// JSON Data를 요청한 payload content 타입으로 역직렬화한다.
    func decode<Payload: SecretPayloadData>(
        _ data: Data,
        as type: Payload.Type
    ) throws -> Payload {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw SecretCryptoError.decodingFailed
        }
    }
}
