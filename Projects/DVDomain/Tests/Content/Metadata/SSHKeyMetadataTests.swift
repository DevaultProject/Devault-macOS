// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("SSHKeyMetadata")
struct SSHKeyMetadataTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(SSHKeyMetadata.schemaVersion == 1)
    }

    @Test("모든 필드가 채워진 경우 Codable roundtrip에서 보존된다")
    func codableRoundtripFullyPopulated() throws {
        try expectCodableRoundtrip(
            SSHKeyMetadata(
                publicKey: "ssh-ed25519 AAAAC3Nz... user@host",
                keyType: "ed25519",
                host: "server.example.com",
                username: "deploy"
            )
        )
    }

    @Test("모든 필드가 nil인 경우에도 Codable roundtrip에서 보존된다")
    func codableRoundtripAllNil() throws {
        try expectCodableRoundtrip(SSHKeyMetadata())
    }
}
