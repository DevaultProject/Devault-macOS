// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("OAuthClientMetadata")
struct OAuthClientMetadataTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(OAuthClientMetadata.schemaVersion == 1)
    }

    @Test("모든 필드가 채워진 경우 Codable roundtrip에서 보존된다")
    func codableRoundtripFullyPopulated() throws {
        try expectCodableRoundtrip(
            OAuthClientMetadata(
                redirectUri: "https://app.example.com/callback",
                scopes: "openid profile email"
            )
        )
    }

    @Test("모든 필드가 nil인 경우에도 Codable roundtrip에서 보존된다")
    func codableRoundtripAllNil() throws {
        try expectCodableRoundtrip(OAuthClientMetadata())
    }
}
