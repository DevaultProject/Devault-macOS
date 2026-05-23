// Copyright © 2026 Devault. All rights reserved

public struct DatabasePayload: SecretPayloadData, Equatable {
    public static let schemaVersion = 1

    public var linkString: String

    public init(linkString: String) {
        self.linkString = linkString
    }
}
