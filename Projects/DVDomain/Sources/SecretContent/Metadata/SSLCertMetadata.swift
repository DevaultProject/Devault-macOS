// Copyright © 2026 Devault. All rights reserved

public struct SSLCertMetadata: SecretMetadataContent, Equatable {
    public static let schemaVersion = 1

    public var domain: String?
    public var issuer: String?
    public var renewCommand: String?

    public init(
        domain: String? = nil,
        issuer: String? = nil,
        renewCommand: String? = nil
    ) {
        self.domain = domain
        self.issuer = issuer
        self.renewCommand = renewCommand
    }
}
