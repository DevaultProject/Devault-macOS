// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("SSLCertPayload")
struct SSLCertPayloadTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(SSLCertPayload.schemaVersion == 1)
    }

    @Test("certificateChain이 있는 경우 Codable roundtrip에서 모든 필드가 보존된다")
    func codableRoundtripWithChain() throws {
        try expectCodableRoundtrip(
            SSLCertPayload(
                certificate: "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----",
                privateKey: "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----",
                certificateChain: "-----BEGIN CERTIFICATE-----\nMIIE...\n-----END CERTIFICATE-----"
            )
        )
    }

    @Test("certificateChain이 nil인 경우에도 Codable roundtrip에서 보존된다")
    func codableRoundtripWithoutChain() throws {
        try expectCodableRoundtrip(
            SSLCertPayload(
                certificate: "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----",
                privateKey: "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----",
                certificateChain: nil
            )
        )
    }
}
