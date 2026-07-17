// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// Devault 디자인 시스템의 여러 줄 입력 필드.
///
/// `DVMultilineTextField`는 ``DVTextField``의 세로 확장 버전입니다.
/// Service Account credentialJSON, SSH privateKey, Env Var Set content 등
/// 여러 줄에 걸친 텍스트 입력이 필요한 곳에서 사용합니다.
///
/// SwiftUI 시스템 `TextEditor`를 그대로 사용하면서 디자인 토큰
/// (``DVColor``, ``DVComponentSize``)으로 시각 속성만 덧입힙니다.
///
/// ## 시각 상태
///
/// | 상태 | 표현 |
/// |------|------|
/// | Empty | `text == ""` — 좌측 상단에 placeholder(``DVColor/gray400``) 오버레이 |
/// | Active | `!text.isEmpty` — 입력 텍스트가 ``DVColor/gray900``로 표시 |
/// | Focus | 시스템 커서가 ``DVColor/vaultGreen``으로 점멸 |
///
/// 외곽선은 항상 1pt ``DVColor/gray300``으로 유지 (``DVTextField``와 동일).
///
/// ## 사이즈
///
/// 너비는 ``DVComponentSize``의 ``DVComponentSize/width``를 그대로 따릅니다.
/// 높이는 ``minHeight`` 이상으로 확장 — 내용이 늘어나면 세로로 커지고,
/// 부모 `ScrollView`가 전체 스크롤을 담당합니다.
///
/// ## 사용
///
/// ```swift
/// @State private var content = ""
///
/// DVMultilineTextField(
///     "e.g DATABASE_URL=postgres://...",
///     text: $content,
///     size: .lg,
///     minHeight: 120
/// )
/// ```
public struct DVMultilineTextField: View {

    // MARK: - Properties

    private let placeholder: String
    @Binding private var text: String
    private let size: DVComponentSize
    private let height: CGFloat

    // MARK: - Init

    /// 여러 줄 텍스트 필드를 생성합니다.
    ///
    /// - Parameters:
    ///   - placeholder: 입력값이 비어 있을 때 좌측 상단에 표시될 안내 문구.
    ///   - text: 입력 값에 대한 양방향 바인딩.
    ///   - size: 너비 변형. 기본값 ``DVComponentSize/lg`` (700pt).
    ///   - height: 고정 높이. 기본값 100pt. 내용이 이 높이를 초과하면 내부에서 세로 스크롤.
    public init(
        _ placeholder: String,
        text: Binding<String>,
        size: DVComponentSize = .lg,
        height: CGFloat = 100
    ) {
        self.placeholder = placeholder
        self._text = text
        self.size = size
        self.height = height
    }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .topLeading) {
            editor
            if text.isEmpty {
                placeholderText
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .frame(width: size.width, height: height, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.dv(.gray300), lineWidth: 1)
        }
    }
}

// MARK: - Subviews

extension DVMultilineTextField {

    // TextEditor는 NSTextView 기반이라 자체 내부 inset이 있습니다.
    // 시각 정렬을 위해 커서 시작 위치(약 leading 5pt, top 8pt)에
    // placeholder를 정확히 겹치도록 padding을 맞춥니다.
    private static let contentInsetLeading: CGFloat = 6
    private static let contentInsetTop: CGFloat = 0

    private var editor: some View {
        TextEditor(text: $text)
            .textEditorStyle(.plain)
            .font(DVFont.bodyLG.font)
            .foregroundStyle(Color.dv(.gray900))
            .tint(Color.dv(.vaultGreen))
            .scrollContentBackground(.hidden)
    }

    private var placeholderText: some View {
        Text(placeholder)
            .font(DVFont.bodyLG.font)
            .foregroundStyle(Color.dv(.gray400))
            .padding(.leading, Self.contentInsetLeading)
            .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview("Empty (Placeholder)") {
    DVMultilineTextFieldEmptyPreview()
        .padding()
}

#Preview("Filled") {
    DVMultilineTextFieldFilledPreview()
        .padding()
}

#Preview("Sizes") {
    DVMultilineTextFieldSizesPreview()
        .padding()
}

private struct DVMultilineTextFieldEmptyPreview: View {
    @State private var text = ""
    var body: some View {
        DVMultilineTextField("e.g DATABASE_URL=...", text: $text, size: .lg)
    }
}

private struct DVMultilineTextFieldFilledPreview: View {
    @State private var text = """
    DATABASE_URL=postgres://user:pass@localhost:5432/mydb
    OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    SECRET_KEY=abc123
    """
    var body: some View {
        DVMultilineTextField("e.g DATABASE_URL=...", text: $text, size: .lg)
    }
}

private struct DVMultilineTextFieldSizesPreview: View {
    @State private var xs = ""
    @State private var sm = ""
    @State private var md = ""
    @State private var lg = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DVMultilineTextField("XS", text: $xs, size: .xs, height: 80)
            DVMultilineTextField("SM", text: $sm, size: .sm, height: 80)
            DVMultilineTextField("MD", text: $md, size: .md, height: 80)
            DVMultilineTextField("LG", text: $lg, size: .lg, height: 100)
        }
    }
}
