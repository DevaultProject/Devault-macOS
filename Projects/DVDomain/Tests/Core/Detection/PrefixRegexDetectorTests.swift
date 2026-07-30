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

    @Test("prefix에 매칭 안 되면 nil (Phase A regex 없음)")
    func noMatch() {
        let result = sut.detect(.testing("random_gibberish_no_prefix"), context: context)
        #expect(result == nil)
    }
}

private struct StubDetectorContext: DetectorContext {
    func detect(_ value: SensitiveString) -> DetectionResult { .none }
}
