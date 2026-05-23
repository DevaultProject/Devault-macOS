// Copyright © 2026 Devault. All rights reserved

public struct ServiceAccountPayload: SecretPayloadData, Equatable {
    public static let schemaVersion = 1

    public var credentialJSON: String

    public init(credentialJSON: String) {
        self.credentialJSON = credentialJSON
    }
}
