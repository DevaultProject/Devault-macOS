// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("InputNormalizer")
struct InputNormalizerTests {
    @Test("앞뒤 공백 · 개행을 trim")
    func trims() {
        #expect(InputNormalizer.normalize("  hello  \n") == "hello")
    }

    @Test("64KB 이하는 그대로 통과")
    func passthroughBelowCap() {
        let raw = "sk-ant-abc"
        #expect(InputNormalizer.normalize(raw) == raw)
    }

    @Test("64KB 초과 시 byte 단위로 잘라낸다")
    func truncatesAboveCap() {
        let raw = String(repeating: "a", count: 100_000)
        let out = InputNormalizer.normalize(raw)
        #expect(out.utf8.count <= InputNormalizer.maxByteCount)
    }

    @Test("UTF-8 multi-byte 문자를 Latin-1로 오변환하지 않는다")
    func preservesUTF8() {
        let raw = "안녕하세요 hello 👋"
        #expect(InputNormalizer.normalize(raw) == raw)
    }

    @Test("multi-byte 경계 중간에서 잘려도 String 자체는 유효 (invalid는 U+FFFD)")
    func handlesBoundaryTruncation() {
        // "가" = 3 bytes. 64KB(65_536)는 3의 배수가 아니라 경계 중간에서 잘림.
        let filler = String(repeating: "가", count: 22_000)
        let out = InputNormalizer.normalize(filler)
        #expect(out.utf8.count <= InputNormalizer.maxByteCount)
        // String 생성 자체가 성공했음 (crash 없음)을 확인
        #expect(!out.isEmpty)
    }
}
