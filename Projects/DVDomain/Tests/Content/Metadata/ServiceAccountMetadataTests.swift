// Copyright © 2026 Devault. All rights reserved

import Testing

import DVDomain

@Suite("ServiceAccountMetadata")
struct ServiceAccountMetadataTests {
    @Test("schemaVersion은 1이다")
    func schemaVersionIsOne() {
        #expect(ServiceAccountMetadata.schemaVersion == 1)
    }

    @Test("모든 필드가 채워진 경우 Codable roundtrip에서 보존된다")
    func codableRoundtripFullyPopulated() throws {
        try expectCodableRoundtrip(
            ServiceAccountMetadata(
                projectId: "my-gcp-project",
                accountEmail: "svc@my-gcp-project.iam.gserviceaccount.com",
                authority: "https://accounts.google.com"
            )
        )
    }

    @Test("모든 필드가 nil인 경우에도 Codable roundtrip에서 보존된다")
    func codableRoundtripAllNil() throws {
        try expectCodableRoundtrip(ServiceAccountMetadata())
    }
}
