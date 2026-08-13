// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// 라벨 + 텍스트 입력을 하나로 묶은 재사용 필드.
/// `isMultiline`에 따라 `DVTextField`(한 줄) 또는 `DVMultilineTextField`(여러 줄)를 감싼다.
///
/// `FormLayout` Environment를 읽어 자기 컴포넌트 사이즈를 결정 —
/// `sizeMode`가 `.fullWidth`면 dual=lg / single=md, `.paired`면 두 모드 모두 md.
///
/// 라벨·필수 표시·`trailingHint` 처리가 두 입력 컴포넌트에서 동일하므로, 별도 뷰를 만들지 않고
/// 이 안에서 content만 교체한다.
struct LabeledTextFieldView: View {

    // MARK: - Metrics

    private enum Metrics {
        /// 여러 줄 입력의 고정 높이. 한 줄 필드의 2배로 잡아 폼의 세로 리듬을 유지한다.
        /// `DVMultilineTextField`의 자체 기본값(100pt)은 폼 밖 단독 사용 기준이라 여기서는 쓰지 않는다.
        static let multilineHeight: CGFloat = DVComponentSize.fieldHeight * 2
    }

    let label: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false
    var isSecure: Bool = false
    /// 여러 줄 입력으로 렌더할지. 내용이 본질적으로 블록인 필드(인증서·개인키·JSON·env 목록)에만 켠다.
    var isMultiline: Bool = false
    var sizeMode: FormSlotSize = .fullWidth
    var trailingHint: DVFieldTrailingHint?

    @Environment(\.formLayout) private var layout

    private var size: DVComponentSize {
        layout.size(for: sizeMode)
    }

    var body: some View {
        if isMultiline {
            DVLabeledField(
                label,
                isRequired: isRequired,
                trailingHint: trailingHint,
                size: size
            ) {
                DVMultilineTextField(
                    placeholder,
                    text: $text,
                    size: size,
                    height: Metrics.multilineHeight,
                    isSecure: isSecure
                )
            }
        } else {
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

/// 여러 줄 + secure. 한 줄 필드의 2배 높이이고, 포커스가 없으면 `•`로 가려진다.
/// 아래 한 줄 필드와 나란히 두어 세로 리듬이 맞는지 함께 확인한다.
#Preview("Multiline · Secure") {
    LabeledMultilinePreview()
        .padding()
        .formLayout(.dual)
        .previewWidth(.wide)
}

private struct LabeledMultilinePreview: View {
    @State private var privateKey = """
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAAB
    -----END OPENSSH PRIVATE KEY-----
    """
    @State private var host = "deploy.devault.local"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabeledTextFieldView(
                label: .module("Private Key"),
                placeholder: .module("e.g -----BEGIN PRIVATE KEY-----"),
                text: $privateKey,
                isRequired: true,
                isSecure: true,
                isMultiline: true
            )
            LabeledTextFieldView(
                label: .module("Host"),
                placeholder: .module("e.g deploy.example.com"),
                text: $host
            )
        }
    }
}

private struct LabeledTextFieldPreview: View {
    let sizeMode: FormSlotSize
    var isSecure: Bool = false
    var hint: DVFieldTrailingHint?

    @State private var text: String

    init(
        sizeMode: FormSlotSize,
        isSecure: Bool = false,
        hint: DVFieldTrailingHint? = nil,
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
