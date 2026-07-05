// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("APIKeyPayload")
struct APIKeyPayloadTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(APIKeyPayload.schemaVersion == 1)
    }

    @Test("Codable roundtrip 시 value가 보존된다")
    func codableRoundtrip() throws {
        try expectCodableRoundtrip(APIKeyPayload(value: "sk_live_51H8xY7abcdefg"))
    }

    @Test("빈 value도 Codable roundtrip에서 보존된다")
    func codableRoundtripWithEmptyValue() throws {
        try expectCodableRoundtrip(APIKeyPayload(value: ""))
    }
}
