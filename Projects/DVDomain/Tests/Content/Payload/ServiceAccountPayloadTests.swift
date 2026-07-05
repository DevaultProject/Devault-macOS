// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("ServiceAccountPayload")
struct ServiceAccountPayloadTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(ServiceAccountPayload.schemaVersion == 1)
    }

    @Test("Codable roundtrip 시 credentialJSON이 보존된다")
    func codableRoundtrip() throws {
        try expectCodableRoundtrip(
            ServiceAccountPayload(
                credentialJSON: #"{"type":"service_account","project_id":"my-project"}"#
            )
        )
    }
}
