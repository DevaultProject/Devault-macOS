// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVPresentation

@Suite("DetailFieldCopyAffordance")
struct DetailFieldCopyAffordanceTests {

    @Test("평문 필드에 값이 있으면 복사 버튼이 붙고 선택은 막힌다")
    func plainWithValue() {
        let affordance = DetailFieldCopyAffordance(
            isSensitive: false,
            isCopyable: true,
            value: "https://app.example/oauth/callback"
        )

        #expect(affordance.showsCopyButton)
        #expect(!affordance.allowsTextSelection)
    }

    @Test("평문 필드가 비면 복사 버튼이 없으므로 선택이 열린다")
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

    /// 복호화 전 민감 필드는 값이 비어 있지만 빈 값 예외를 적용할 수 없다 —
    /// 비었는지 알 수 없고, 마스킹 placeholder는 선택시켜 봐야 얻을 것도 없다.
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

    @Test("민감 필드여도 복사 대상이 아니면 선택이 열린다")
    func sensitiveNotCopyable() {
        let affordance = DetailFieldCopyAffordance(
            isSensitive: true,
            isCopyable: false,
            value: "ghp_1234567890abcdef"
        )

        #expect(!affordance.showsCopyButton)
        #expect(affordance.allowsTextSelection)
    }

    /// 이 대응이 깨지면 복사 버튼이 있는 필드에 ⌘C가 열려 `ClipboardCopyPolicy`가 통째로 우회된다.
    @Test("선택 허용은 언제나 복사 버튼 노출의 반대다")
    func selectionIsAlwaysTheInverseOfCopyButton() {
        for isSensitive in [true, false] {
            for isCopyable in [true, false] {
                for value in ["", "value"] {
                    let affordance = DetailFieldCopyAffordance(
                        isSensitive: isSensitive,
                        isCopyable: isCopyable,
                        value: value
                    )
                    #expect(affordance.allowsTextSelection == !affordance.showsCopyButton)
                }
            }
        }
    }
}
