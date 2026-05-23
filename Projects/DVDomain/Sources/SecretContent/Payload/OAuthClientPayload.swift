// Copyright © 2026 Devault. All rights reserved

public struct OAuthClientPayload: SecretPayloadData, Equatable {
    public static let schemaVersion = 1

    public var clientId: String
    public var clientSecret: String

    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
}
