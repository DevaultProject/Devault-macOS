// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("SSLCertMetadata")
struct SSLCertMetadataTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(SSLCertMetadata.schemaVersion == 1)
    }

    @Test("모든 필드가 채워진 경우 Codable roundtrip에서 보존된다")
    func codableRoundtripFullyPopulated() throws {
        try expectCodableRoundtrip(
            SSLCertMetadata(
                domain: "example.com",
                issuer: "Let's Encrypt",
                renewCommand: "certbot renew"
            )
        )
    }

    @Test("모든 필드가 nil인 경우에도 Codable roundtrip에서 보존된다")
    func codableRoundtripAllNil() throws {
        try expectCodableRoundtrip(SSLCertMetadata())
    }
}
