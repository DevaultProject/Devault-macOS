// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("OAuthClientPayload")
struct OAuthClientPayloadTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(OAuthClientPayload.schemaVersion == 1)
    }

    @Test("Codable roundtrip 시 clientId와 clientSecret이 모두 보존된다")
    func codableRoundtrip() throws {
        try expectCodableRoundtrip(
            OAuthClientPayload(clientId: "client_abc123", clientSecret: "secret_xyz789")
        )
    }
}
