// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// CreateSecret 폼의 Name 필드 (모든 secretType 공통, required).
/// `SecretMetaFields.name`에 바인딩. Save 시도 시 매핑 실패면 `warning` 파라미터로 인라인 경고 표시.
struct NameFieldView: View {

    @Binding var name: String
    var warning: String?

    var body: some View {
        LabeledTextFieldView(
            label: .module("Name"),
            placeholder: .module("e.g DeVault"),
            text: $name,
            isRequired: true,
            sizeMode: .fullWidth,
            trailingHint: warning.map { .warning($0) }
        )
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Empty · Dual") {
    NameFieldPreview()
        .padding()
        .formLayout(.dual)
        .previewWidth(.wide)
}

#Preview("Filled · Single") {
    NameFieldPreview(initial: "My API Key")
        .padding()
        .formLayout(.single)
        .previewWidth(.narrow)
}

#Preview("With warning · Dual") {
    NameFieldPreview(warning: "Required")
        .padding()
        .formLayout(.dual)
        .previewWidth(.wide)
}

private struct NameFieldPreview: View {
    @State private var name: String
    var warning: String?

    init(initial: String = "", warning: String? = nil) {
        self._name = State(initialValue: initial)
        self.warning = warning
    }

    var body: some View {
        NameFieldView(name: $name, warning: warning)
    }
}

#endif
