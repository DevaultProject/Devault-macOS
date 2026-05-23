// Copyright © 2026 Devault. All rights reserved

public struct SSHKeyPayload: SecretPayloadData, Equatable {
    public static let schemaVersion = 1

    public var privateKey: String
    public var passphrase: String?

    public init(privateKey: String, passphrase: String? = nil) {
        self.privateKey = privateKey
        self.passphrase = passphrase
    }
}
