// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("CustomPayload")
struct CustomPayloadTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(CustomPayload.schemaVersion == 1)
    }

    @Test("Codable roundtrip 시 value가 보존된다")
    func codableRoundtrip() throws {
        try expectCodableRoundtrip(CustomPayload(value: "custom-arbitrary-string"))
    }
}
