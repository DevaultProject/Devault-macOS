// Copyright © 2026 Devault. All rights reserved

public struct CustomPayload: SecretPayloadData, Equatable {
    public static let schemaVersion = 1

    public var value: String

    public init(value: String) {
        self.value = value
    }
}
