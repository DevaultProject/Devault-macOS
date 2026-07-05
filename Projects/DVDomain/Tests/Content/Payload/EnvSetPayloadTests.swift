// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("EnvSetPayload")
struct EnvSetPayloadTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(EnvSetPayload.schemaVersion == 1)
    }

    @Test("여러 줄로 이루어진 content가 Codable roundtrip에서 보존된다")
    func codableRoundtrip() throws {
        try expectCodableRoundtrip(
            EnvSetPayload(
                content: """
                DB_HOST=localhost
                DB_PORT=5432
                API_KEY=abc123
                """
            )
        )
    }
}
