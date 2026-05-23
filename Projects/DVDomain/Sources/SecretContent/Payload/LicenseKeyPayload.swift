// Copyright © 2026 Devault. All rights reserved

public struct LicenseKeyPayload: SecretPayloadData, Equatable {
    public static let schemaVersion = 1

    public var licenseKey: String

    public init(licenseKey: String) {
        self.licenseKey = licenseKey
    }
}
