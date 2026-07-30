// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("PrefixRegexDetector")
struct PrefixRegexDetectorTests {
    private let sut = PrefixRegexDetector(
        prefixRules: BuiltInPrefixRules.all,
        regexRules: BuiltInRegexRules.all
    )
    private let context = StubDetectorContext()

    @Test("sk-ant- 매칭 시 Anthropic 후보 하나만 반환한다 (긴 prefix 우선)")
    func anthropicWinsOverGenericSk() {
        let raw = DetectionFixture.anthropicToken()
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.count == 1)
        #expect(result?.candidates.first?.service == "Anthropic")
        #expect(result?.candidates.first?.confidence == .high)
    }

    @Test("sk- + 48자 이상 + 컨텍스트 없음 → OpenAI(.medium) 단독")
    func openAIWithoutContext() {
        let raw = "sk-" + String(repeating: "a", count: 48)
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.count == 1)
        #expect(result?.candidates.first?.service == "OpenAI")
        #expect(result?.candidates.first?.confidence == .medium)
    }

    @Test("sk- + stability 컨텍스트 → Stability(.high) + OpenAI(.medium) 둘 다, high가 먼저")
    func stabilityContextIncludesBoth() {
        let raw = DetectionFixture.stabilityToken()
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.count == 2)
        #expect(result?.candidates[0].service == "Stability AI")
        #expect(result?.candidates[0].confidence == .high)
        #expect(result?.candidates[1].service == "OpenAI")
    }

    @Test("sk- + 47자 → minLength 미충족 → nil")
    func openAIRejectsShortToken() {
        let raw = "sk-" + String(repeating: "a", count: 44) // total 47
        let result = sut.detect(.testing(raw), context: context)
        #expect(result == nil)
    }

    @Test("hf_ 매칭")
    func huggingFace() {
        let result = sut.detect(.testing("hf_abcdef1234567890"), context: context)
        #expect(result?.candidates.first?.service == "Hugging Face")
    }

    @Test("매칭되는 prefix · regex rule 없으면 nil")
    func noMatch() {
        let result = sut.detect(.testing("random_gibberish_no_prefix"), context: context)
        #expect(result == nil)
    }

    // MARK: - 확장 카탈로그 sanity

    @Test("Stripe live · GitHub PAT · Notion secret_ · Google ya29. 등 개별 prefix 매칭")
    func expandedPrefixCatalog() {
        let cases: [(String, String)] = [
            ("sk_live_abc123", "Stripe"),
            ("ghp_abcdef1234567890", "GitHub"),
            ("secret_notion_abc", "Notion"),
            ("ya29.abcXYZ", "Google"),
            ("xoxb-1-2-3", "Slack"),
            ("dop_v1_abcdef", "DigitalOcean"),
            ("NRAK-abcdef1234", "New Relic"),
            ("shpat_abcdef123", "Shopify"),
        ]
        for (raw, expected) in cases {
            let result = sut.detect(.testing(raw), context: context)
            #expect(
                result?.candidates.first?.service == expected,
                "'\(raw)' should map to \(expected), got \(result?.candidates.first?.service ?? "nil")"
            )
        }
    }

    @Test("AKIA prefix은 minLength 20 미만이면 매칭 안 됨")
    func awsAccessKeyMinLength() {
        #expect(sut.detect(.testing("AKIA123"), context: context) == nil)
        let ok = sut.detect(.testing("AKIA" + String(repeating: "A", count: 16)), context: context)
        #expect(ok?.candidates.first?.service == "AWS")
    }

    @Test("HubSpot 토큰은 Airtable로 오탐되지 않는다 (`.` 컨텍스트 요구)")
    func hubspotNotConfusedWithAirtable() {
        let result = sut.detect(.testing("pat-na1-xxxxx-yyyy"), context: context)
        #expect(result?.candidates.map(\.service) == ["HubSpot"])
    }

    @Test("Airtable 토큰(`.` 포함)은 Airtable로 매칭")
    func airtableWithDot() {
        let result = sut.detect(.testing("patAaBbCcDdEe.fghij1234"), context: context)
        #expect(result?.candidates.first?.service == "Airtable")
    }

    @Test("Twilio Account SID regex — AC + 32자 hex")
    func twilioSID() {
        let raw = "AC" + String(repeating: "a", count: 32)
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.first?.service == "Twilio")
    }

    @Test("Sentry DSN regex")
    func sentryDSN() {
        let raw = "https://abcdef1234@o12345.ingest.sentry.io/1234567"
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.first?.service == "Sentry")
    }
}

private struct StubDetectorContext: DetectorContext {
    func detect(_ value: SensitiveString) -> DetectionResult { .none }
}
