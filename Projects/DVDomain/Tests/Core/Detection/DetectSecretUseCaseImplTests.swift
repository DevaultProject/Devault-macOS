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

    // MARK: - 스펙 §1~6 커버리지

    @Test("JWT → metadata.jwt (alg · iss · sub · exp)")
    func jwtIntegration() {
        let raw = DetectionFixture.jwt(
            header: ["alg": "HS256"],
            payload: ["iss": "auth.example.com", "sub": "42", "exp": 1_900_000_000]
        )
        let result = sut.execute(value: .testing(raw))
        guard case .jwt(let info) = result.metadata else {
            Issue.record("expected .jwt metadata")
            return
        }
        #expect(info.algorithm == "HS256")
        #expect(info.issuer == "auth.example.com")
    }

    @Test("Anthropic sk-ant- → Anthropic 단독 후보")
    func anthropic() {
        let result = sut.execute(value: .testing("sk-ant-abcdefghijklmnopqrst"))
        #expect(result.candidates.map(\.service) == ["Anthropic"])
    }

    @Test("GitHub PAT ghp_ → GitHub")
    func githubPAT() {
        let result = sut.execute(value: .testing("ghp_abcdef1234567890ABCDEF"))
        #expect(result.candidates.first?.service == "GitHub")
    }

    @Test("Stripe Live sk_live_ → Stripe")
    func stripeLive() {
        let result = sut.execute(value: .testing("sk_live_abcdef1234567890"))
        #expect(result.candidates.first?.service == "Stripe")
    }

    @Test("Slack Bot xoxb- → Slack")
    func slackBot() {
        let result = sut.execute(value: .testing("xoxb-1234-5678-abcdef"))
        #expect(result.candidates.first?.service == "Slack")
    }

    @Test("AWS AKIA + 16자 → AWS")
    func awsAccessKey() {
        let result = sut.execute(value: .testing("AKIA" + String(repeating: "A", count: 16)))
        #expect(result.candidates.first?.service == "AWS")
    }

    @Test("Twilio Account SID regex → Twilio")
    func twilioSID() {
        let result = sut.execute(value: .testing("AC" + String(repeating: "a", count: 32)))
        #expect(result.candidates.first?.service == "Twilio")
    }

    @Test("GCP Service Account JSON → candidate + project_id 파싱")
    func gcpServiceAccount() {
        let raw = """
            {"type":"service_account","project_id":"prj-123","client_email":"svc@prj.iam"}
            """
        let result = sut.execute(value: .testing(raw))
        #expect(result.candidates.first?.service == "GCP Service Account")
        guard case .json(let info) = result.metadata else {
            Issue.record("expected .json")
            return
        }
        #expect(info.projectId == "prj-123")
    }

    @Test("Google OAuth Client JSON → candidate + redirect_uris")
    func googleOAuthClient() {
        let raw = """
            {"installed":{"client_id":"cid.apps","client_secret":"s","redirect_uris":["http://localhost"]}}
            """
        let result = sut.execute(value: .testing(raw))
        #expect(result.candidates.first?.service == "Google OAuth Client")
    }

    @Test(".env 세트 재귀 → 3개 subDetection")
    func envSetRecursion() {
        let raw = """
            OPENAI_API_KEY=sk-\(String(repeating: "a", count: 48))
            DATABASE_URL=postgres://user:pw@host:5432/db
            RANDOM_NOTE=nothing
            """
        let result = sut.execute(value: .testing(raw))
        #expect(result.subDetections.count == 3)
        #expect(result.subDetections[0].result.candidates.first?.service == "OpenAI")
        #expect(result.subDetections[2].result == .none)
    }

    @Test("Azure Storage 커넥션 문자열 → Azure Storage")
    func azureStorage() {
        let raw = "DefaultEndpointsProtocol=https;AccountName=x;AccountKey=y;EndpointSuffix=core.windows.net"
        let result = sut.execute(value: .testing(raw))
        #expect(result.candidates.first?.service == "Azure Storage")
    }

    @Test("Neon 호스트 postgres URL → Neon candidate + .database metadata")
    func neonURL() {
        let result = sut.execute(value: .testing(DetectionFixture.neonURL))
        #expect(result.candidates.first?.service == "Neon")
        guard case .database(let info) = result.metadata else {
            Issue.record("expected .database")
            return
        }
        #expect(info.host?.hasSuffix(".neon.tech") == true)
    }

    @Test("OpenSSH ed25519 → PEM metadata + algorithm='ed25519'")
    func opensshEd25519() {
        let result = sut.execute(value: .testing(DetectionFixture.pemOpenSSHEd25519))
        guard case .pemKey(let info) = result.metadata else {
            Issue.record("expected .pemKey")
            return
        }
        #expect(info.keyType == "OpenSSH")
        #expect(info.algorithm == "ed25519")
    }
}
