// Copyright © 2026 Devault. All rights reserved

public struct APIKeyMetadata: SecretMetadataContent, Equatable {
    public static let schemaVersion = 1

    public var scope: String?

    public init(scope: String? = nil) {
        self.scope = scope
    }
}
