// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// Devault 디자인 시스템 스타일이 입혀진 텍스트 입력 필드.
///
/// `DVTextField`는 SwiftUI의 시스템 `TextField`를 그대로 사용하면서 디자인
/// 토큰(`DVColor`, ``DVComponentSize``)으로 시각 속성만 덧입힙니다.
/// 입력 동작·접근성·국제화·키보드 동작은 모두 시스템 컨트롤이 제공하는 것을 그대로 따릅니다.
///
/// ## 시각 상태
///
/// Figma의 4가지 variant는 다음과 같이 자연스럽게 표현됩니다:
///
/// | Figma variant | 표현 방식 |
/// |---------------|----------|
/// | Empty | `text == ""` 이고 포커스 없음 |
/// | Placeholder | `text == ""` 이고 포커스 없음 — `prompt`가 ``DVColor/gray400``으로 표시 |
/// | Active | `!text.isEmpty` — 입력된 텍스트가 ``DVColor/gray900``로 표시 |
/// | Focus | 포커스 진입 — 시스템 커서가 ``DVColor/vaultGreen``으로 점멸 (`.tint`) |
///
/// 외곽선은 모든 상태에서 1pt ``DVColor/gray300`` 으로 유지됩니다 — 포커스
/// 시에도 외곽선 색은 변하지 않으며, 활성 상태는 오직 커서 색으로만
/// 표현하는 것이 디자인 의도입니다.
///
/// ## 사이즈
///
/// 너비는 ``DVComponentSize``의 `width`를 그대로 따릅니다. 높이는 28pt
/// 고정. 폼 안에서 다른 사이즈를 섞어 쓰지 않는 것을 권장.
///
/// ## Secure 모드
///
/// `isSecure: true`이면 값이 `SecureField`로 마스킹되고 우측에 눈 아이콘 토글이
/// 자동 표시됩니다. 마스킹 상태는 내부 `@State`로 관리됩니다.
public struct DVTextField: View {

    // MARK: - Properties

    private let placeholder: String
    @Binding private var text: String
    private let size: DVComponentSize
    private let isSecure: Bool

    @State private var isRevealed = false

    // MARK: - Init

    /// 텍스트 필드를 생성합니다.
    ///
    /// - Parameters:
    ///   - placeholder: 입력값이 비어 있을 때 ``DVColor/gray400`` 으로 표시될
    ///     안내 문구.
    ///   - text: 입력 값에 대한 양방향 바인딩. 시스템 `TextField` 에 그대로
    ///     전달되므로 IME(한글/일본어/중국어 등) 입력도 정상 동작합니다.
    ///   - size: 너비 변형. 기본값은 ``DVComponentSize/md``.
    ///   - isSecure: 민감 정보 마스킹 여부. `true`이면 `SecureField` 사용 +
    ///     우측 눈 아이콘 토글이 자동으로 추가됩니다. 기본값 `false`.
    public init(
        _ placeholder: String,
        text: Binding<String>,
        size: DVComponentSize = .md,
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        self._text = text
        self.size = size
        self.isSecure = isSecure
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 0) {
            inputField
            if isSecure {
                revealToggle
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .frame(width: size.width, height: 28)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.dv(.gray300), lineWidth: 1)
        }
    }
}

// MARK: - Subviews

extension DVTextField {

    private var promptText: Text {
        Text(placeholder).foregroundStyle(Color.dv(.gray400))
    }

    @ViewBuilder
    private var inputField: some View {
        Group {
            if isSecure && !isRevealed {
                SecureField("", text: $text, prompt: promptText)
            } else {
                TextField("", text: $text, prompt: promptText)
            }
        }
        .textFieldStyle(.plain)
        .font(DVFont.bodyLG.font)
        .foregroundStyle(Color.dv(.gray900))
        .tint(Color.dv(.vaultGreen))
    }

    private var revealToggle: some View {
        Button {
            isRevealed.toggle()
        } label: {
            Image(systemName: isRevealed ? "eye.slash" : "eye")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.dv(.gray900))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Placeholder (Empty)") {
    DVTextFieldPlaceholderPreview()
        .padding()
}

#Preview("Active (Filled)") {
    DVTextFieldFilledPreview()
        .padding()
}

#Preview("Sizes") {
    DVTextFieldSizesPreview()
        .padding()
}

#Preview("Secure") {
    DVTextFieldSecurePreview()
        .padding()
}

private struct DVTextFieldPlaceholderPreview: View {
    @State private var text = ""
    var body: some View {
        DVTextField("e.g DeVault", text: $text, size: .md)
    }
}

private struct DVTextFieldFilledPreview: View {
    @State private var text = "DeVault"
    var body: some View {
        DVTextField("e.g DeVault", text: $text, size: .md)
    }
}

private struct DVTextFieldSizesPreview: View {
    @State private var xs = ""
    @State private var sm = ""
    @State private var md = "DeVault"
    @State private var lg = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DVTextField("XS", text: $xs, size: .xs)
            DVTextField("SM", text: $sm, size: .sm)
            DVTextField("MD", text: $md, size: .md)
            DVTextField("LG", text: $lg, size: .lg)
        }
    }
}

private struct DVTextFieldSecurePreview: View {
    @State private var apiKey = "ghp_1234567890abcdef"
    @State private var empty = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DVTextField("secret value", text: $apiKey, size: .lg, isSecure: true)
            DVTextField("empty secure", text: $empty, size: .lg, isSecure: true)
        }
    }
}
