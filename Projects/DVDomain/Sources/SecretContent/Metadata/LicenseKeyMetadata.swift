// Copyright © 2026 Devault. All rights reserved

public struct LicenseKeyMetadata: SecretMetadataContent, Equatable {
    public static let schemaVersion = 1

    public var licenseType: String?
    public var registrationEmail: String?
    public var orderNumber: String?
    public var website: String?

    public init(
        licenseType: String? = nil,
        registrationEmail: String? = nil,
        orderNumber: String? = nil,
        website: String? = nil
    ) {
        self.licenseType = licenseType
        self.registrationEmail = registrationEmail
        self.orderNumber = orderNumber
        self.website = website
    }
}
