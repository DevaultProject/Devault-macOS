// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("DatabaseMetadata")
struct DatabaseMetadataTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(DatabaseMetadata.schemaVersion == 1)
    }

    @Test("모든 필드가 채워진 경우 Codable roundtrip에서 보존된다")
    func codableRoundtripFullyPopulated() throws {
        try expectCodableRoundtrip(
            DatabaseMetadata(
                host: "db.example.com",
                port: 5432,
                databaseName: "production",
                username: "app_user",
                sslRequired: true
            )
        )
    }

    @Test("모든 필드가 nil인 경우에도 Codable roundtrip에서 보존된다")
    func codableRoundtripAllNil() throws {
        try expectCodableRoundtrip(DatabaseMetadata())
    }

    @Test("일부 필드만 채워진 경우에도 Codable roundtrip에서 보존된다")
    func codableRoundtripPartial() throws {
        try expectCodableRoundtrip(
            DatabaseMetadata(host: "db.example.com", port: 5432)
        )
    }
}
