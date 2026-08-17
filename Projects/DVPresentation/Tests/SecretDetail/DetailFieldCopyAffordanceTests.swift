// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVPresentation

@Suite("DetailFieldCopyAffordance")
struct DetailFieldCopyAffordanceTests {

    @Test("평문 필드는 복사 버튼이 붙어도 선택이 함께 열린다")
    func plainWithValue() {
        let affordance = DetailFieldCopyAffordance(
            isSensitive: false,
            isCopyable: true,
            value: "https://app.example/oauth/callback"
        )

        #expect(affordance.showsCopyButton)
        #expect(affordance.allowsTextSelection)
    }

    @Test("평문 필드가 비면 복사 버튼이 사라지고 선택은 그대로 열린다")
    func plainEmpty() {
        let affordance = DetailFieldCopyAffordance(
            isSensitive: false,
            isCopyable: true,
            value: ""
        )

        #expect(!affordance.showsCopyButton)
        #expect(affordance.allowsTextSelection)
    }

    @Test("복사 대상이 아닌 필드는 선택이 열린다")
    func notCopyable() {
        let affordance = DetailFieldCopyAffordance(
            isSensitive: false,
            isCopyable: false,
            value: "GitHub"
        )

        #expect(!affordance.showsCopyButton)
        #expect(affordance.allowsTextSelection)
    }

    @Test("민감 필드는 복호화 전이어도 복사 버튼이 붙고 선택은 막힌다")
    func sensitiveBeforeReveal() {
        let affordance = DetailFieldCopyAffordance(
            isSensitive: true,
            isCopyable: true,
            value: ""
        )

        #expect(affordance.showsCopyButton)
        #expect(!affordance.allowsTextSelection)
    }

    /// 눈 토글은 `isCopyable`과 무관하게 살아 있어 reveal 후 평문이 그대로 ⌘C로 나간다.
    @Test("민감 필드는 복사 대상이 아니어도 선택이 막힌다")
    func sensitiveNotCopyable() {
        let affordance = DetailFieldCopyAffordance(
            isSensitive: true,
            isCopyable: false,
            value: "ghp_1234567890abcdef"
        )

        #expect(!affordance.showsCopyButton)
        #expect(!affordance.allowsTextSelection)
    }

    /// 판정이 `isCopyable`이나 값 유무로 새면 그 조합에서 `ClipboardCopyPolicy.sensitive`가
    /// 통째로 우회되므로 전수로 못박는다.
    @Test("민감 필드는 어떤 조합에서도 선택이 막힌다")
    func sensitiveNeverAllowsSelection() {
        for isCopyable in [true, false] {
            for value in ["", "ghp_1234567890abcdef"] {
                let affordance = DetailFieldCopyAffordance(
                    isSensitive: true,
                    isCopyable: isCopyable,
                    value: value
                )
                #expect(!affordance.allowsTextSelection)
            }
        }
    }

    @Test("평문 필드는 어떤 조합에서도 선택이 열린다")
    func plainAlwaysAllowsSelection() {
        for isCopyable in [true, false] {
            for value in ["", "https://app.example/oauth/callback"] {
                let affordance = DetailFieldCopyAffordance(
                    isSensitive: false,
                    isCopyable: isCopyable,
                    value: value
                )
                #expect(affordance.allowsTextSelection)
            }
        }
    }
}
