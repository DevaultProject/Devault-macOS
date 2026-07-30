// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("PEMDetector")
struct PEMDetectorTests {
    private let sut = PEMDetector(rules: BuiltInPEMHeaders.all)
    private let context = StubDetectorContext()

    @Test("RSA 프라이빗 키 → metadata=.pemKey(RSA), candidates 비어있음")
    func rsaPrivateKey() {
        let result = sut.detect(.testing(DetectionFixture.pemRSA), context: context)
        #expect(result?.candidates.isEmpty == true)
        if case .pemKey(let info) = result?.metadata {
            #expect(info.keyType == "RSA")
            #expect(info.algorithm == nil)
        } else {
            Issue.record("expected .pemKey(RSA)")
        }
    }

    @Test("OpenSSH ed25519 → algorithm='ed25519'")
    func opensshEd25519() {
        let result = sut.detect(.testing(DetectionFixture.pemOpenSSHEd25519), context: context)
        if case .pemKey(let info) = result?.metadata {
            #expect(info.keyType == "OpenSSH")
            #expect(info.algorithm == "ed25519")
        } else {
            Issue.record("expected .pemKey(OpenSSH)")
        }
    }

    @Test("X509 인증서 → metadata=.certificate")
    func certificate() {
        let result = sut.detect(.testing(DetectionFixture.pemCertificate), context: context)
        guard case .certificate = result?.metadata else {
            Issue.record("expected .certificate")
            return
        }
    }

    @Test("PEM 헤더 없으면 nil")
    func noHeader() {
        let result = sut.detect(.testing("just a random string"), context: context)
        #expect(result == nil)
    }
}

private struct StubDetectorContext: DetectorContext {
    func detect(_ value: SensitiveString) -> DetectionResult { .none }
}
