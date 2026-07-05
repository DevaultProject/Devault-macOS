// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("LicenseKeyMetadata")
struct LicenseKeyMetadataTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(LicenseKeyMetadata.schemaVersion == 1)
    }

    @Test("모든 필드가 채워진 경우 Codable roundtrip에서 보존된다")
    func codableRoundtripFullyPopulated() throws {
        try expectCodableRoundtrip(
            LicenseKeyMetadata(
                licenseType: "commercial",
                registrationEmail: "user@example.com",
                orderNumber: "ORD-2026-0001",
                website: "https://example.com"
            )
        )
    }

    @Test("모든 필드가 nil인 경우에도 Codable roundtrip에서 보존된다")
    func codableRoundtripAllNil() throws {
        try expectCodableRoundtrip(LicenseKeyMetadata())
    }
}
