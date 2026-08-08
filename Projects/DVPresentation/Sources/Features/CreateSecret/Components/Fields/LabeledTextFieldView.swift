// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// 라벨 + 텍스트 입력 (`DVLabeledField` + `DVTextField`)을 하나로 묶은 재사용 필드.
///
/// `FormLayout` Environment를 읽어 자기 컴포넌트 사이즈를 결정 —
/// `sizeMode`가 `.fullWidth`면 dual=lg / single=md, `.paired`면 두 모드 모두 md.
struct LabeledTextFieldView: View {

    let label: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false
    var isSecure: Bool = false
    var sizeMode: FormSlotSize = .fullWidth
    var trailingHint: DVLabeledField<DVTextField>.TrailingHint?

    @Environment(\.formLayout) private var layout

    private var size: DVComponentSize {
        layout.size(for: sizeMode)
    }

    var body: some View {
        DVLabeledField(
            label,
            isRequired: isRequired,
            trailingHint: trailingHint,
            size: size
        ) {
            DVTextField(placeholder, text: $text, size: size, isSecure: isSecure)
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Full-width · Dual") {
    LabeledTextFieldPreview(sizeMode: .fullWidth)
        .padding()
        .formLayout(.dual)
        .previewWidth(.wide)
}

#Preview("Full-width · Single") {
    LabeledTextFieldPreview(sizeMode: .fullWidth)
        .padding()
        .formLayout(.single)
        .previewWidth(.narrow)
}

#Preview("Paired · Dual") {
    LabeledTextFieldPreview(sizeMode: .paired)
        .padding()
        .formLayout(.dual)
        .previewWidth(.wide)
}

#Preview("Secure + Detected hint") {
    LabeledTextFieldPreview(
        sizeMode: .fullWidth,
        isSecure: true,
        hint: .detected("Auto-detected: GitHub"),
        initial: "ghp_1234567890"
    )
    .padding()
    .formLayout(.dual)
    .previewWidth(.wide)
}

#Preview("Warning hint") {
    LabeledTextFieldPreview(
        sizeMode: .fullWidth,
        hint: .warning("Required")
    )
    .padding()
    .formLayout(.dual)
    .previewWidth(.wide)
}

private struct LabeledTextFieldPreview: View {
    let sizeMode: FormSlotSize
    var isSecure: Bool = false
    var hint: DVLabeledField<DVTextField>.TrailingHint?

    @State private var text: String

    init(
        sizeMode: FormSlotSize,
        isSecure: Bool = false,
        hint: DVLabeledField<DVTextField>.TrailingHint? = nil,
        initial: String = ""
    ) {
        self.sizeMode = sizeMode
        self.isSecure = isSecure
        self.hint = hint
        self._text = State(initialValue: initial)
    }

    var body: some View {
        LabeledTextFieldView(
            label: .module("Sample"),
            placeholder: .module("e.g DeVault"),
            text: $text,
            isRequired: true,
            isSecure: isSecure,
            sizeMode: sizeMode,
            trailingHint: hint
        )
    }
}

#endif
