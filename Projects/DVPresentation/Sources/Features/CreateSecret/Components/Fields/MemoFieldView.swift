// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// CreateSecret 폼의 Memo 필드 (모든 secretType 공통, optional).
/// `SecretMetaFields.memo`에 바인딩. Figma 실측상 단일 라인 텍스트 필드 (28pt).
struct MemoFieldView: View {

    @Binding var memo: String

    var body: some View {
        LabeledTextFieldView(
            label: .module("Memo"),
            placeholder: .module("optional"),
            text: $memo,
            sizeMode: .fullWidth
        )
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Empty · Dual") {
    MemoFieldPreview()
        .padding()
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Filled · Single") {
    MemoFieldPreview(initial: "Rotate quarterly")
        .padding()
        .environment(\.formLayoutMode, .single)
        .previewWidth(.narrow)
}

private struct MemoFieldPreview: View {
    @State private var memo: String

    init(initial: String = "") {
        _memo = State(initialValue: initial)
    }

    var body: some View {
        MemoFieldView(memo: $memo)
    }
}

#endif
