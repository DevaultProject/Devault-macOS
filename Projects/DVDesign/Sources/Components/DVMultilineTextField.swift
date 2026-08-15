// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 여러 줄 입력 필드. ``DVTextField``의 세로 확장 버전.
///
/// 너비는 ``DVComponentSize``, 높이는 `height` 파라미터로 고정.
/// 내용이 초과하면 내부에서 세로 스크롤됩니다.
///
/// ## Secure 모드
///
/// `isSecure: true`이면 **포커스가 없는 동안** 값을 줄 단위 `•`로 가립니다. 클릭해 포커스가 가면
/// 평문 편집으로 바뀌고, 포커스를 잃으면 다시 가려집니다. 빈 값은 가리지 않습니다 —
/// 가릴 것이 없고 placeholder가 보여야 합니다.
///
/// ``DVTextField``와 **동작이 다릅니다.** 단일 줄은 `SecureField`라 포커스가 있어도 계속 가려지지만,
/// SwiftUI에 멀티라인 `SecureField`가 없습니다. 마스킹된 문자열을 `TextEditor`에 바인딩하면 편집이
/// 원문에 매핑되지 않아 값이 깨지므로, 대신 에디터의 글자 색을 투명으로 바꾸고 위에 `•`를 겹칩니다.
///
/// 에디터는 가리는 동안에도 뷰 트리에 남습니다. 빼버리면 `@FocusState`를 `true`로 써도 받을 뷰가
/// 없어 SwiftUI가 포커스를 되돌리고, 클릭해도 편집으로 들어갈 수 없습니다.
public struct DVMultilineTextField: View {

    // MARK: - Metrics

    private enum Metrics {
        static let cornerRadius: CGFloat = 6
        static let borderWidth: CGFloat = 1

        /// 박스 안쪽 여백. `TextEditor`가 자체 여백을 더 갖는다.
        static let contentPadding: CGFloat = 4

        /// placeholder·마스킹 표시의 좌측 inset. `TextEditor` 내부 여백에 맞춘 값이라
        /// 평문과 첫 글자 위치가 어긋나지 않는다.
        static let textLeadingInset: CGFloat = 6
    }

    // MARK: - Properties

    private let placeholder: String
    @Binding private var text: String
    private let size: DVComponentSize
    private let height: CGFloat
    private let isSecure: Bool

    @FocusState private var isFocused: Bool

    /// 에디터 재생성 트리거. 값이 바뀌면 `TextEditor`가 새 인스턴스로 교체되어 선택 영역이 사라진다.
    ///
    /// `NSTextView`는 first responder가 아니어도 선택 하이라이트를 계속 그린다. secure 필드에서는
    /// 그 사각형이 가려진 값의 줄·단어 길이를 드러내므로, 포커스를 잃을 때 에디터를 버린다.
    ///
    /// 포커스를 **얻을** 때는 올리지 않는다 — 그 순간 뷰가 교체되면 방금 들어온 포커스를 잃는다.
    @State private var editorGeneration = 0

    // MARK: - Init

    /// 여러 줄 텍스트 필드를 생성합니다.
    ///
    /// - Parameters:
    ///   - placeholder: 입력값이 비어 있을 때 좌측 상단에 표시될 안내 문구.
    ///   - text: 입력 값에 대한 양방향 바인딩.
    ///   - size: 너비 변형. 기본값 ``DVComponentSize/lg`` (700pt).
    ///   - height: 고정 높이. 기본값 100pt. 내용이 이 높이를 초과하면 내부에서 세로 스크롤.
    ///   - isSecure: 민감 값 마스킹 여부. 기본 `false`.
    ///     `true`면 포커스가 없고 값이 비어 있지 않은 동안 줄 단위 `•`로 가립니다.
    public init(
        _ placeholder: String,
        text: Binding<String>,
        size: DVComponentSize = .lg,
        // `Metrics`가 private이라 기본값에 쓸 수 없다 — public init의 기본값은 호출부에서 보여야 한다.
        height: CGFloat = 100,
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        self._text = text
        self.size = size
        self.height = height
        self.isSecure = isSecure
    }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .topLeading) {
            editor
            if text.isEmpty {
                placeholderText
            }
            if showsMask {
                maskedText
            }
        }
        .padding(Metrics.contentPadding)
        .dvComponentWidth(size, height: height, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(Color.dv(.gray300), lineWidth: Metrics.borderWidth)
        }
        .onChange(of: isFocused) { _, focused in
            guard isSecure, !focused else { return }
            editorGeneration += 1
        }
    }
}

// MARK: - Subviews

extension DVMultilineTextField {

    private var editor: some View {
        TextEditor(text: $text)
            .textEditorStyle(.plain)
            .font(DVFont.bodyLG.font)
            .foregroundStyle(showsMask ? Color.clear : Color.dv(.gray900))
            .tint(Color.dv(.vaultGreen))
            .scrollContentBackground(.hidden)
            .focused($isFocused)
            .id(editorGeneration)
    }

    private var placeholderText: some View {
        Text(placeholder)
            .font(DVFont.bodyLG.font)
            .foregroundStyle(Color.dv(.gray400))
            .padding(.leading, Metrics.textLeadingInset)
            .allowsHitTesting(false)
    }
}

// MARK: - Secure

extension DVMultilineTextField {

    /// 가리는 조건. 빈 값은 가릴 것이 없으므로 제외한다 — placeholder가 보여야 한다.
    private var showsMask: Bool {
        isSecure && !isFocused && !text.isEmpty
    }

    /// 투명해진 평문 위에 겹쳐 그리는 마스킹 표시.
    ///
    /// 클릭을 통과시켜(`allowsHitTesting(false)`) 아래 에디터가 포커스를 받게 한다 — 탭 제스처를
    /// 쓰면 커서 위치 지정 클릭까지 가로챈다. 좌측 inset을 placeholder와 같은 값으로 맞춰
    /// 마스킹·평문의 첫 글자 위치를 일치시킨다.
    private var maskedText: some View {
        Text(maskedValue)
            .font(DVFont.bodyLG.font)
            .foregroundStyle(Color.dv(.gray900))
            .lineSpacing(DVFont.bodyLG.lineSpacing)
            .padding(.leading, Metrics.textLeadingInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .allowsHitTesting(false)
    }

    /// 줄 구조를 유지한 마스킹 값. 전체를 하나의 `•` 덩어리로 만들지 않는다 —
    /// 가려진 상태에서도 몇 줄이 채워졌는지 확인할 수 있어야 한다.
    /// 조회 화면(``DVMultilineTextContainer`` 호출부)이 쓰는 규칙과 같다.
    private var maskedValue: String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String(repeating: "•", count: $0.count) }
            .joined(separator: "\n")
    }
}

// MARK: - Previews

#if DEBUG

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

/// 포커스가 없으면 줄 단위 `•`, 클릭해 포커스가 가면 평문 편집.
/// 다른 필드로 포커스를 옮기면 자동으로 다시 가려지는지 함께 확인한다.
#Preview("Secure · Filled") {
    DVMultilineTextFieldSecurePreview()
        .padding()
}

/// 빈 값은 가리지 않는다 — placeholder가 그대로 보이고 바로 타이핑할 수 있어야 한다.
#Preview("Secure · Empty") {
    DVMultilineTextFieldSecureEmptyPreview()
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

private struct DVMultilineTextFieldSecurePreview: View {
    @State private var secret = """
    PREVIEW PLACEHOLDER — 실제 키가 아니다
    포커스가 빠졌을 때 여러 줄이 통째로 마스킹되는지 보기 위한 자리 채움 텍스트
    세 번째 줄
    """
    @State private var other = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DVMultilineTextField("private key", text: $secret, size: .lg, isSecure: true)
            DVMultilineTextField("포커스를 옮겨 재마스킹 확인", text: $other, size: .lg, height: 60)
        }
    }
}

private struct DVMultilineTextFieldSecureEmptyPreview: View {
    @State private var text = ""
    var body: some View {
        DVMultilineTextField("e.g DATABASE_URL=...", text: $text, size: .lg, isSecure: true)
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

#endif
