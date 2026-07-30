// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("DatabaseURLDetector")
struct DatabaseURLDetectorTests {
    private let sut = DatabaseURLDetector(schemes: BuiltInDatabaseSchemes.all)
    private let context = StubDetectorContext()

    @Test("postgres URL → scheme/host/port/dbName/username 파싱")
    func postgresURL() {
        let result = sut.detect(.testing(DetectionFixture.postgresURL), context: context)
        if case .database(let info) = result?.metadata {
            #expect(info.scheme == "postgres")
            #expect(info.host == "host.example.com")
            #expect(info.port == 5432)
            #expect(info.databaseName == "mydb")
            #expect(info.username == "user")
        } else {
            Issue.record("expected .database")
        }
        #expect(result?.candidates.isEmpty == true)
    }

    @Test("포트 미지정 시 scheme 기본 포트로 채워진다")
    func fillsDefaultPort() {
        let result = sut.detect(.testing("mysql://user@host/db"), context: context)
        if case .database(let info) = result?.metadata {
            #expect(info.port == 3306)
        } else {
            Issue.record("expected .database")
        }
    }

    @Test("neon.tech 호스트 → Neon candidate")
    func neonHostCandidate() {
        let result = sut.detect(.testing(DetectionFixture.neonURL), context: context)
        #expect(result?.candidates.first?.service == "Neon")
        #expect(result?.candidates.first?.confidence == .high)
    }

    @Test("mongodb+srv scheme 지원")
    func mongoSRVScheme() {
        let result = sut.detect(.testing(DetectionFixture.mongoSRV), context: context)
        if case .database(let info) = result?.metadata {
            #expect(info.scheme == "mongodb+srv")
            #expect(info.host == "cluster0.abc.mongodb.net")
            #expect(info.port == nil) // defaultPort=nil
        } else {
            Issue.record("expected .database")
        }
    }

    @Test("알 수 없는 scheme → nil")
    func unknownScheme() {
        let result = sut.detect(.testing("https://example.com"), context: context)
        #expect(result == nil)
    }

    // MARK: - Azure key=value fallback

    @Test("Azure Storage 커넥션 문자열 → Azure Storage 후보")
    func azureStorage() {
        let raw = "DefaultEndpointsProtocol=https;AccountName=devault;AccountKey=abcd==;EndpointSuffix=core.windows.net"
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.first?.service == "Azure Storage")
        #expect(result?.metadata == nil)
    }

    @Test("Azure Service Bus 커넥션 문자열 → Azure Service Bus 후보")
    func azureServiceBus() {
        let raw = "Endpoint=sb://devault.servicebus.windows.net/;SharedAccessKeyName=Root;SharedAccessKey=abc"
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.first?.service == "Azure Service Bus")
    }

    @Test("Azure SQL 커넥션 문자열 → Azure SQL 후보")
    func azureSQL() {
        let raw = "Server=tcp:devault.database.windows.net,1433;Database=devaultdb;User ID=admin;Password=secret;"
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.first?.service == "Azure SQL")
    }
}

private struct StubDetectorContext: DetectorContext {
    func detect(_ value: SensitiveString) -> DetectionResult { .none }
}
