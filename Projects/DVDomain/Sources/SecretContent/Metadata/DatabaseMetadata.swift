// Copyright © 2026 Devault. All rights reserved

public struct DatabaseMetadata: SecretMetadataContent, Equatable {
    public static let schemaVersion = 1

    public var host: String?
    public var port: Int?
    public var databaseName: String?
    public var username: String?
    public var sslRequired: Bool?

    public init(
        host: String? = nil,
        port: Int? = nil,
        databaseName: String? = nil,
        username: String? = nil,
        sslRequired: Bool? = nil
    ) {
        self.host = host
        self.port = port
        self.databaseName = databaseName
        self.username = username
        self.sslRequired = sslRequired
    }
}
