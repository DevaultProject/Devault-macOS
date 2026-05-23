// Copyright © 2026 Devault. All rights reserved

public enum SecretCryptoError: Error, Equatable, Sendable {
    case keyUnavailable
    case encryptionFailed
    case decryptionFailed
    case encodingFailed
    case decodingFailed
}
