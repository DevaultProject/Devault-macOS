// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("DetectSecretUseCaseImpl 골든")
struct DetectSecretUseCaseImplTests {
    private let sut = DetectSecretUseCaseImpl()

    @Test("OpenAI sk- 48자")
    func openAI() {
        let raw = "sk-" + String(repeating: "a", count: 48)
        let result = sut.execute(value: .testing(raw))
        #expect(result.candidates.first?.service == "OpenAI")
        #expect(result.candidates.first?.confidence == .medium)
        #expect(result.metadata == nil)
    }

    @Test("sk- + stability 컨텍스트 → Stability + OpenAI 후보 둘 다")
    func stabilityContext() {
        let raw = DetectionFixture.stabilityToken()
        let result = sut.execute(value: .testing(raw))
        #expect(result.candidates.count == 2)
        #expect(result.candidates[0].service == "Stability AI")
        #expect(result.candidates[0].confidence == .high)
    }

    @Test("PEM RSA → metadata만 채워짐")
    func pemRSA() {
        let result = sut.execute(value: .testing(DetectionFixture.pemRSA))
        #expect(result.candidates.isEmpty)
        if case .pemKey(let info) = result.metadata {
            #expect(info.keyType == "RSA")
        } else {
            Issue.record("expected .pemKey")
        }
    }

    @Test("postgres URL → .database metadata")
    func postgresURL() {
        let result = sut.execute(value: .testing(DetectionFixture.postgresURL))
        if case .database(let info) = result.metadata {
            #expect(info.host == "host.example.com")
            #expect(info.port == 5432)
        } else {
            Issue.record("expected .database")
        }
    }

    @Test("빈 입력 · 공백만 → .none")
    func empty() {
        #expect(sut.execute(value: .testing("   ")) == .none)
        #expect(sut.execute(value: .testing("")) == .none)
    }

    @Test("prefix/regex/DB/PEM 매칭 없으면 .none")
    func noMatch() {
        let result = sut.execute(value: .testing("random_no_match_string"))
        #expect(result == .none)
    }
}
