// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 여러 줄 입력 필드. ``DVTextField``의 세로 확장 버전.
///
/// 너비는 ``DVComponentSize``, 높이는 `height` 파라미터로 고정.
/// 내용이 초과하면 내부에서 세로 스크롤됩니다.
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

    private static let placeholderLeadingInset: CGFloat = 6

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
            .padding(.leading, Self.placeholderLeadingInset)
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
