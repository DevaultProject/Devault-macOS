// Copyright © 2026 Devault. All rights reserved

public struct OAuthClientMetadata: SecretMetadataContent, Equatable {
    public static let schemaVersion = 1

    public var redirectUri: String?
    public var scopes: String?

    public init(redirectUri: String? = nil, scopes: String? = nil) {
        self.redirectUri = redirectUri
        self.scopes = scopes
    }
}
