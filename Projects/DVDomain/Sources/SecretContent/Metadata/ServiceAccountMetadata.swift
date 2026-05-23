// Copyright © 2026 Devault. All rights reserved

public struct ServiceAccountMetadata: SecretMetadataContent, Equatable {
    public static let schemaVersion = 1

    public var projectId: String?
    public var accountEmail: String?
    public var authority: String?

    public init(
        projectId: String? = nil,
        accountEmail: String? = nil,
        authority: String? = nil
    ) {
        self.projectId = projectId
        self.accountEmail = accountEmail
        self.authority = authority
    }
}
