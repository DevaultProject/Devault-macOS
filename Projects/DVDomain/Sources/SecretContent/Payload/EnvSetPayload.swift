// Copyright © 2026 Devault. All rights reserved

public struct EnvSetPayload: SecretPayloadData, Equatable {
    public static let schemaVersion = 1

    public var content: String

    public init(content: String) {
        self.content = content
    }
}
