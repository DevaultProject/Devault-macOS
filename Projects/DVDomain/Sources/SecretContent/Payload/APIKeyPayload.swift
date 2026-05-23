// Copyright © 2026 Devault. All rights reserved

public struct APIKeyPayload: SecretPayloadData, Equatable {
    public static let schemaVersion = 1

    public var value: String

    public init(value: String) {
        self.value = value
    }
}
