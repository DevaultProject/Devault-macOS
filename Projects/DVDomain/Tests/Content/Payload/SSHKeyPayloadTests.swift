// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("SSHKeyPayload")
struct SSHKeyPayloadTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(SSHKeyPayload.schemaVersion == 1)
    }

    @Test("passphrase가 있는 경우 Codable roundtrip에서 모든 필드가 보존된다")
    func codableRoundtripWithPassphrase() throws {
        try expectCodableRoundtrip(
            SSHKeyPayload(
                privateKey: "-----BEGIN OPENSSH PRIVATE KEY-----\nMIIB...\n-----END OPENSSH PRIVATE KEY-----",
                passphrase: "my-strong-passphrase"
            )
        )
    }

    @Test("passphrase가 nil인 경우에도 Codable roundtrip에서 보존된다")
    func codableRoundtripWithoutPassphrase() throws {
        try expectCodableRoundtrip(
            SSHKeyPayload(
                privateKey: "-----BEGIN OPENSSH PRIVATE KEY-----\nMIIB...\n-----END OPENSSH PRIVATE KEY-----",
                passphrase: nil
            )
        )
    }
}
