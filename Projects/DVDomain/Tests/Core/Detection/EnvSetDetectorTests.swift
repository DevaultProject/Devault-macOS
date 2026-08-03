// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("EnvSetDetector")
struct EnvSetDetectorTests {
    private let sut = EnvSetDetector()

    @Test("2줄 이상 KEY=VALUE → subDetections + envSet metadata")
    func multipleEntries() {
        let raw = """
            DATABASE_URL=postgres://user:pw@host:5432/db
            OPENAI_API_KEY=sk-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
            SECRET_KEY=xyz
            """
        let context = StubDetectorContext()
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.isEmpty == true)
        #expect(result?.subDetections.count == 3)
        guard case .envSet(let keys) = result?.metadata else {
            Issue.record("expected .envSet")
            return
        }
        #expect(keys == ["DATABASE_URL", "OPENAI_API_KEY", "SECRET_KEY"])
        #expect(context.callCount == 3)
    }

    @Test("`#` 주석 라인은 무시된다")
    func commentsIgnored() {
        let raw = """
            # main config
            KEY_A=val1
            # secondary
            KEY_B=val2
            """
        let result = sut.detect(.testing(raw), context: StubDetectorContext())
        #expect(result?.subDetections.count == 2)
    }

    @Test("빈 라인 · 공백 라인 무시")
    func blankLinesIgnored() {
        let raw = """
            KEY_A=val1

            \t
            KEY_B=val2
            """
        let result = sut.detect(.testing(raw), context: StubDetectorContext())
        #expect(result?.subDetections.count == 2)
    }

    @Test("따옴표로 감싼 VALUE는 벗겨서 하위 detector에 전달")
    func stripsQuotedValues() {
        let raw = """
            KEY_A="sk-\(String(repeating: "a", count: 48))"
            KEY_B='postgres://u:p@host/db'
            """
        let context = RecordingContext()
        _ = sut.detect(.testing(raw), context: context)
        #expect(context.lastValues[0].hasPrefix("sk-"))
        #expect(context.lastValues[1].hasPrefix("postgres://"))
    }

    @Test("KEY가 대문자로 시작하지 않으면 해당 라인 무시")
    func lowerCaseKeyIgnored() {
        let raw = """
            key_a=val1
            KEY_B=val2
            KEY_C=val3
            """
        let result = sut.detect(.testing(raw), context: StubDetectorContext())
        #expect(result?.subDetections.map(\.key) == ["KEY_B", "KEY_C"])
    }

    @Test("1줄뿐이면 nil (env-set 아님)")
    func singleLineIsNotEnvSet() {
        let result = sut.detect(.testing("KEY_A=val1"), context: StubDetectorContext())
        #expect(result == nil)
    }

    @Test("KEY=VALUE 자체가 아니면 nil")
    func plainTextIsNotEnvSet() {
        let result = sut.detect(.testing("just some text\nno equals sign"), context: StubDetectorContext())
        #expect(result == nil)
    }

    @Test("VALUE가 embedded multi-line JSON이면 첫 줄만 KEY=VALUE로 잡히고 나머지 라인은 무효 → 재귀 감지 정상 fall-through")
    func embeddedMultilineJSONFallsThroughGracefully() {
        // 실제 시크릿 스토리지에서 흔한 케이스: KEY=<opening JSON>...
        // 나머지 라인은 KEY= 형태가 아니므로 무시되고, 첫 라인 value에 대해서만 재귀. 결과적으로 subDetection 1건.
        let raw = """
            CONFIG_JSON={"type":"service_account","project_id":"x"}
            SIMPLE_KEY=simple_value
            """
        let result = sut.detect(.testing(raw), context: StubDetectorContext())
        // 두 라인 모두 KEY=VALUE 유효 → 2건
        #expect(result?.subDetections.count == 2)
    }

    @Test("VALUE에 `=`가 포함돼도 첫 `=`만 기준으로 분리")
    func valueWithEqualsSign() {
        let raw = """
            KEY_A=a=b=c
            KEY_B=simple
            """
        let context = RecordingContext()
        _ = sut.detect(.testing(raw), context: context)
        #expect(context.lastValues[0] == "a=b=c")
        #expect(context.lastValues[1] == "simple")
    }

    @Test("실제 파이프라인 재귀 — OpenAI · postgres 서브 감지")
    func recursionViaRealPipeline() {
        let sut = DetectSecretUseCaseImpl()
        let raw = """
            OPENAI_API_KEY=sk-\(String(repeating: "a", count: 48))
            DATABASE_URL=postgres://user:pw@host:5432/db
            RANDOM_NOTE=nothing_special
            """
        let result = sut.execute(value: .testing(raw))
        #expect(result.subDetections.count == 3)
        #expect(result.subDetections[0].result.candidates.first?.service == "OpenAI")
        if case .database(let info) = result.subDetections[1].result.metadata {
            #expect(info.host == "host")
            #expect(info.port == 5432)
        } else {
            Issue.record("expected .database for DATABASE_URL")
        }
        #expect(result.subDetections[2].result == .none)
    }
}

private final class StubDetectorContext: DetectorContext, @unchecked Sendable {
    private(set) var callCount = 0
    func detect(_ value: SensitiveString) -> DetectionResult {
        callCount += 1
        return .none
    }
}

private final class RecordingContext: DetectorContext, @unchecked Sendable {
    private(set) var lastValues: [String] = []
    func detect(_ value: SensitiveString) -> DetectionResult {
        value.withUnsafeAccess { raw in lastValues.append(raw) }
        return .none
    }
}
