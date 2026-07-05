// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("APIKeyMetadata")
struct APIKeyMetadataTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(APIKeyMetadata.schemaVersion == 1)
    }

    @Test("scope가 있는 경우 Codable roundtrip에서 보존된다")
    func codableRoundtripWithScope() throws {
        try expectCodableRoundtrip(APIKeyMetadata(scope: "read:user"))
    }

    @Test("scope가 nil인 경우에도 Codable roundtrip에서 보존된다")
    func codableRoundtripWithNilScope() throws {
        try expectCodableRoundtrip(APIKeyMetadata(scope: nil))
    }
}
