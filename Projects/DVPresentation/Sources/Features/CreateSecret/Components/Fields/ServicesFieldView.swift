// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// CreateSecret 폼의 Services 필드.
///
/// 사용자 액션 2가지:
/// - **Chip 탭**: `DVChipsField`가 자동으로 chip 텍스트를 `input`에 세팅. `input`과 일치하는 chip은 자동 숨김.
/// - **직접 입력**: 사용자가 텍스트필드에 자유롭게 타이핑.
///
/// Chip 목록은 외부(감지 엔진 등)에서 주입되며, 이 필드 안에서는 chip이 추가/삭제되지 않는다.
/// 저장 시엔 `input` 값이 그대로 `SecretDraft.service`로 매핑 (빈 문자열이면 `nil`).
struct ServicesFieldView: View {

    /// 외부(감지 엔진 등)에서 주입되는 chip 후보 목록. 순수 표시용.
    let suggestedChips: [String]

    /// 현재 사용자 입력. chip 탭 or 직접 타이핑으로 변경.
    @Binding var input: String

    @Environment(\.formLayoutMode) private var mode

    private var size: DVComponentSize { mode.pairedFieldSize }

    var body: some View {
        DVLabeledField("Services", size: size) {
            DVChipsField(
                "e.g. github.com",
                chips: suggestedChips,
                input: $input,
                size: size
            )
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Empty · No suggestions · Dual") {
    ServicesFieldPreview(suggestions: [])
        .padding()
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("With suggestions · Dual") {
    ServicesFieldPreview(suggestions: ["github.com", "gitlab.com", "bitbucket.org"])
        .padding()
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Input matches chip · Single") {
    ServicesFieldPreview(
        suggestions: ["github.com", "gitlab.com"],
        initialInput: "github.com"
    )
    .padding()
    .environment(\.formLayoutMode, .single)
    .previewWidth(.narrow)
}

private struct ServicesFieldPreview: View {
    let suggestions: [String]
    @State private var input: String

    init(suggestions: [String], initialInput: String = "") {
        self.suggestions = suggestions
        _input = State(initialValue: initialInput)
    }

    var body: some View {
        ServicesFieldView(suggestedChips: suggestions, input: $input)
    }
}

#endif
