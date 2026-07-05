// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("DatabasePayload")
struct DatabasePayloadTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(DatabasePayload.schemaVersion == 1)
    }

    @Test("Codable roundtrip 시 linkString이 보존된다")
    func codableRoundtrip() throws {
        try expectCodableRoundtrip(
            DatabasePayload(linkString: "postgres://user:pass@db.example.com:5432/mydb")
        )
    }
}
