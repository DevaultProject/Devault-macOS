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

    @Test("Twitter Bearer AAAA prefix — 80자 미만이면 매칭 안 됨")
    func twitterBearerMinLength() {
        let short = "AAAA" + String(repeating: "x", count: 70)
        #expect(sut.detect(.testing(short), context: context) == nil)
        let ok = "AAAA" + String(repeating: "x", count: 76)
        #expect(sut.detect(.testing(ok), context: context)?.candidates.first?.service == "Twitter")
    }

    @Test("Meta EAA prefix — 50자 미만이면 매칭 안 됨")
    func metaMinLength() {
        #expect(sut.detect(.testing("EAA"), context: context) == nil)
        #expect(sut.detect(.testing("EAAshort"), context: context) == nil)
        let ok = "EAA" + String(repeating: "x", count: 47)
        #expect(sut.detect(.testing(ok), context: context)?.candidates.first?.service == "Meta")
    }

    @Test("Airtable — pat 시작이라도 20자 미만이면 오탐 없음 (예: `patient.txt`)")
    func airtableMinLengthRejectsFalsePositive() {
        #expect(sut.detect(.testing("patient.txt"), context: context) == nil)
        #expect(sut.detect(.testing("pat.short"), context: context) == nil)
    }

    @Test("Discord regex — JSON blob 안 embedded substring은 wholeMatch로 걸러진다")
    func discordSubstringNotFalsePositive() {
        let embedded = #"{"token": "MTk4NjIyNDgzNDcxOTI1MjQ4.abcdef.abc123def456ghi789jkl0mnop"}"#
        let result = sut.detect(.testing(embedded), context: context)
        #expect(result?.candidates.first?.service != "Discord")
    }

    @Test("SendGrid SG. · Doppler dp.st. 개별 prefix")
    func sendGridAndDoppler() {
        #expect(sut.detect(.testing("SG.abc.def"), context: context)?.candidates.first?.service == "SendGrid")
        #expect(sut.detect(.testing("dp.st.abcdef1234"), context: context)?.candidates.first?.service == "Doppler")
    }

    @Test("HashiCorp Vault s. — 24자 미만 미매칭, 24자 이상 매칭")
    func hashiCorpBoundary() {
        #expect(sut.detect(.testing("s.short"), context: context) == nil)
        let ok = "s." + String(repeating: "a", count: 22) // total 24
        #expect(sut.detect(.testing(ok), context: context)?.candidates.first?.service == "HashiCorp Vault")
    }

    @Test("Mailgun regex — key- + 32자 hex")
    func mailgunRegex() {
        let raw = "key-" + String(repeating: "a", count: 32)
        #expect(sut.detect(.testing(raw), context: context)?.candidates.first?.service == "Mailgun")
    }

    @Test("Mailchimp regex — {32자}-us{숫자}")
    func mailchimpRegex() {
        let raw = String(repeating: "a", count: 32) + "-us1"
        #expect(sut.detect(.testing(raw), context: context)?.candidates.first?.service == "Mailchimp")
    }

    @Test("Telegram regex — {숫자}:{35자}")
    func telegramRegex() {
        let raw = "123456789:" + String(repeating: "A", count: 35)
        #expect(sut.detect(.testing(raw), context: context)?.candidates.first?.service == "Telegram")
    }

    @Test("Toss Payments — test_sk_/live_sk_/test_ak_/live_ak_ prefix 매칭")
    func tossPayments() {
        let cases: [(String, String)] = [
            ("test_sk_abcdef1234567890", "Toss Payments Test Secret Key"),
            ("live_sk_abcdef1234567890", "Toss Payments Live Secret Key"),
            ("test_ak_abcdef1234567890", "Toss Payments Test API Key"),
            ("live_ak_abcdef1234567890", "Toss Payments Live API Key"),
        ]
        for (raw, expected) in cases {
            let result = sut.detect(.testing(raw), context: context)
            #expect(result?.candidates.first?.service == "Toss Payments")
            #expect(result?.candidates.first?.displayLabel == expected)
        }
    }

    @Test("PayPal Client ID — A21 prefix + 50자 이상")
    func paypalClientID() {
        #expect(sut.detect(.testing("A21" + String(repeating: "a", count: 40)), context: context) == nil)
        let ok = "A21" + String(repeating: "a", count: 50)
        #expect(sut.detect(.testing(ok), context: context)?.candidates.first?.service == "PayPal")
    }

    @Test("Azure Storage Connection String regex")
    func azureStorageConnectionString() {
        let key = String(repeating: "a", count: 86) + "=="
        let raw = "DefaultEndpointsProtocol=https;AccountName=mystorageacct;AccountKey=\(key);EndpointSuffix=core.windows.net"
        #expect(sut.detect(.testing(raw), context: context)?.candidates.first?.service == "Azure")
    }

    @Test("Cloudinary URL regex")
    func cloudinaryURL() {
        let raw = "CLOUDINARY_URL=cloudinary://123456789012345:abcDEF-ghiJKL_mno@my-cloud-name"
        #expect(sut.detect(.testing(raw), context: context)?.candidates.first?.service == "Cloudinary")
    }
}

private struct StubDetectorContext: DetectorContext {
    func detect(_ value: SensitiveString) -> DetectionResult { .none }
}
