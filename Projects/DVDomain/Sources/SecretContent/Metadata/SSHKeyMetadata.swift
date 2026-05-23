// Copyright © 2026 Devault. All rights reserved

public struct SSHKeyMetadata: SecretMetadataContent, Equatable {
    public static let schemaVersion = 1

    public var publicKey: String?
    public var keyType: String?
    public var host: String?
    public var username: String?

    public init(
        publicKey: String? = nil,
        keyType: String? = nil,
        host: String? = nil,
        username: String? = nil
    ) {
        self.publicKey = publicKey
        self.keyType = keyType
        self.host = host
        self.username = username
    }
}
