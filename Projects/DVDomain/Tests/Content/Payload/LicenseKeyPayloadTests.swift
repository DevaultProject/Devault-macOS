// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("LicenseKeyPayload")
struct LicenseKeyPayloadTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(LicenseKeyPayload.schemaVersion == 1)
    }

    @Test("Codable roundtrip 시 licenseKey가 보존된다")
    func codableRoundtrip() throws {
        try expectCodableRoundtrip(
            LicenseKeyPayload(licenseKey: "XXXXX-YYYYY-ZZZZZ-AAAAA-BBBBB")
        )
    }
}
