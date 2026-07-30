// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("JWTDetector")
struct JWTDetectorTests {
    private let sut = JWTDetector()
    private let context = StubDetectorContext()

    @Test("표준 3-part JWT → alg · iss · sub · exp 파싱")
    func parsesStandardClaims() {
        let expUnix: TimeInterval = 1_900_000_000
        let raw = DetectionFixture.jwt(
            header: ["alg": "RS256", "typ": "JWT"],
            payload: ["iss": "https://example.com", "sub": "user-42", "exp": Int(expUnix)]
        )
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.isEmpty == true)
        guard case .jwt(let info) = result?.metadata else {
            Issue.record("expected .jwt metadata")
            return
        }
        #expect(info.algorithm == "RS256")
        #expect(info.issuer == "https://example.com")
        #expect(info.subject == "user-42")
        #expect(info.expiresAt == Date(timeIntervalSince1970: expUnix))
    }

    @Test("alg=none · 서명 빈 3-part도 파싱한다")
    func acceptsUnsignedJWT() {
        let raw = DetectionFixture.jwt(
            header: ["alg": "none"],
            payload: ["sub": "anon"],
            signature: ""
        )
        let result = sut.detect(.testing(raw), context: context)
        guard case .jwt(let info) = result?.metadata else {
            Issue.record("expected .jwt")
            return
        }
        #expect(info.algorithm == "none")
        #expect(info.subject == "anon")
    }

    @Test("eyJ prefix 없으면 nil")
    func rejectsNonJWTPrefix() {
        let result = sut.detect(.testing("not-a-jwt"), context: context)
        #expect(result == nil)
    }

    @Test("`.` 2개 미만이면 nil (part 부족)")
    func rejectsMissingParts() {
        let result = sut.detect(.testing("eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0In0"), context: context)
        #expect(result == nil)
    }

    @Test("깨진 base64 → nil (JSON 파싱 실패)")
    func rejectsBrokenBase64() {
        let result = sut.detect(.testing("eyJ!!!.eyJ###.sig"), context: context)
        #expect(result == nil)
    }

    @Test("optional claim 없으면 해당 필드도 nil")
    func absentClaimsAreNil() {
        let raw = DetectionFixture.jwt(header: ["alg": "HS256"], payload: [:])
        let result = sut.detect(.testing(raw), context: context)
        guard case .jwt(let info) = result?.metadata else {
            Issue.record("expected .jwt")
            return
        }
        #expect(info.algorithm == "HS256")
        #expect(info.issuer == nil)
        #expect(info.subject == nil)
        #expect(info.expiresAt == nil)
    }
}

private struct StubDetectorContext: DetectorContext {
    func detect(_ value: SensitiveString) -> DetectionResult { .none }
}
