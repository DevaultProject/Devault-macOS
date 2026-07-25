// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// 라벨 + 텍스트 입력 (`DVLabeledField` + `DVTextField`)을 하나로 묶은 재사용 필드.
///
/// `FormLayoutMode` Environment를 읽어 자기 컴포넌트 사이즈를 결정 —
/// `sizeMode`가 `.fullWidth`면 dual=lg / single=md, `.paired`면 두 모드 모두 md.
struct LabeledTextFieldView: View {

    /// 이 필드가 폼에서 어떤 슬롯을 차지하는지.
    enum SizeMode: Equatable {
        /// 행 전체를 차지하는 필드 (Name, Value, Memo 등).
        case fullWidth
        /// 2-col row 안의 한 칸을 차지하는 필드.
        case paired
    }

    let label: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false
    var isSecure: Bool = false
    var sizeMode: SizeMode = .fullWidth
    var trailingHint: DVLabeledField<DVTextField>.TrailingHint?

    @Environment(\.formLayoutMode) private var mode

    private var size: DVComponentSize {
        switch sizeMode {
        case .fullWidth: return mode.fullWidthFieldSize
        case .paired:    return mode.pairedFieldSize
        }
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
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Full-width · Single") {
    LabeledTextFieldPreview(sizeMode: .fullWidth)
        .padding()
        .environment(\.formLayoutMode, .single)
        .previewWidth(.narrow)
}

#Preview("Paired · Dual") {
    LabeledTextFieldPreview(sizeMode: .paired)
        .padding()
        .environment(\.formLayoutMode, .dual)
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
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Warning hint") {
    LabeledTextFieldPreview(
        sizeMode: .fullWidth,
        hint: .warning("Required")
    )
    .padding()
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

private struct LabeledTextFieldPreview: View {
    let sizeMode: LabeledTextFieldView.SizeMode
    var isSecure: Bool = false
    var hint: DVLabeledField<DVTextField>.TrailingHint?

    @State private var text: String

    init(
        sizeMode: LabeledTextFieldView.SizeMode,
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
