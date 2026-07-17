// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 디자인 시스템 스타일의 읽기 전용 텍스트 표시 컨테이너.
///
/// `DVTextContainer`는 입력을 받지 않고 정해진 텍스트를 박스 안에 표시하는 컴포넌트입니다.
/// ``DVTextField``와 시각적으로 짝을 이루는 read-only counterpart로, 비밀번호 마스킹값·복사 가능한 토큰·환경 정보 같은 "표시 전용 값"을 노출할 때 사용합니다.
///
/// ## 시각 상태
///
/// | 상태 | 설명 |
/// |------|------|
/// | Filled | 본문 텍스트가 ``DVColor/gray900`` 으로 표시 |
/// | Empty | `text == ""` — 박스만 보이고 콘텐츠 없음 |
/// | hasAccessories | 우측에 **인터랙티브** 액세서리(복사·표시 토글 등) 배치 |
///
/// 외곽선은 없고 ``DVColor/gray300`` 배경 채움으로 박스 형태를 표현합니다.
///
/// ## 오버플로우 처리
///
/// 본문 텍스트가 컨테이너 너비(`size.width`)보다 길 경우, **잘리지 않고 가로 스크롤**됩니다.
/// 사용자는 트랙패드 두 손가락 제스처 또는 마우스 휠(가로)로 가려진 부분까지 모두 확인할 수 있습니다.
/// 스크롤 인디케이터는 표시되지 않아(`showsIndicators: false`) UI가 깔끔하게 유지됩니다.
///
/// 오버플로우 상태로 스크롤되어도 본문 텍스트와 액세서리 사이에는 **최소 8pt 간격**이 항상 보장되어 글자가 액세서리 버튼에 들러붙지 않습니다.
///
/// ``DVTextField``의 시스템 `TextField`도 입력 텍스트가 폭을 넘으면 동일하게 가로 시프트로 처리하므로, 두 컴포넌트의 오버플로우 동작은 일관됩니다.
///
/// ## 텍스트 선택·복사
///
/// 본문에 `.textSelection(.enabled)`이 적용되어 있어, 사용자가 마우스 드래그 또는 ⌘+A로 텍스트를 선택하고 ⌘+C로 클립보드에 복사할 수 있습니다. 가로 스크롤로 가려진 부분도 드래그를 이어가며 선택 가능합니다.
/// ``init(copyable:size:onCopy:)`` 편의 init과 별도로 동작하므로 둘 다 함께 활용 가능합니다.
///
/// ## 액세서리
///
/// 액세서리는 항상 **인터랙티브**(`Button` 기반)로 사용한다는 전제로 설계되었습니다.
/// 단순 장식용 아이콘은 ``DVTextContainer``의 디자인 의도가 아니므로 사용하지 않습니다.
/// 액세서리 액션은 외부 `@State`나 콜백을 통해 컨테이너에 표시되는 `text`에 영향을 주는 식으로 연결됩니다.
///
/// ## Interactive 액세서리
///
/// 액세서리 안에 `Button`을 두면 그 액션이 외부 `@State`를 갱신해 **컨테이너에 표시되는 텍스트 자체를 바꾸는** 패턴이 자연스럽게 성립합니다.
/// 호출자가 텍스트의 source of truth를 소유하고, 컨테이너는 그 값을 그릴 뿐입니다(상태 끌어올리기).
///
/// 가장 흔한 두 가지 케이스는 사전 정의된 편의 이니셜라이저로 제공되어 보일러플레이트 없이 사용할 수 있습니다:
///
/// | 케이스 | 편의 init |
/// |--------|----------|
/// | 비밀번호 마스킹 + 눈 토글 | ``init(secured:isRevealed:size:)`` |
/// | 복사 버튼 | ``init(copyable:size:onCopy:)`` |
/// | 기타 단일 액세서리(아이콘+액션) | ``init(_:size:onTap:icon:)`` |
/// | 멀티 액세서리 / 임의 구성 | ``init(_:size:accessories:)`` |
///
/// 사전 정의 init은 모두 ``DVColor/gray900`` SF Symbol 11pt 아이콘 +
/// `.buttonStyle(.plain)` 처리를 자동 적용합니다.
///
/// ## 사용
///
/// ```swift
/// // 단순 표시 (액세서리 없음)
/// DVTextContainer("DeVault", size: .md)
///
/// // 비밀번호 마스킹 + 표시 토글 내장
/// @State var revealed = false
/// DVTextContainer(secured: "SuperSecret", isRevealed: $revealed, size: .md)
///
/// // 복사 버튼 내장 (클립보드는 호출자가 작성)
/// DVTextContainer(copyable: "token", size: .md) {
///     NSPasteboard.general.setString("token", forType: .string)
/// }
///
/// // 커스텀 단일 아이콘 + 액션 주입
/// DVTextContainer("https://...", size: .md, onTap: openURL) {
///     Image(systemName: "arrow.up.right.square")
///         .font(.system(size: 11))
///         .foregroundStyle(Color.dv(.gray900))
/// }
///
/// // 두 개 이상의 인터랙티브 액세서리는 기본 init으로 직접 합치기
/// DVTextContainer("token", size: .md) {
///     HStack(spacing: 10) {
///         Button { copy() } label: { Image(systemName: "doc.on.doc") }
///         Button { revealed.toggle() } label: {
///             Image(systemName: revealed ? "eye.slash" : "eye")
///         }
///     }
///     .font(.system(size: 11))
///     .foregroundStyle(Color.dv(.gray900))
///     .buttonStyle(.plain)
/// }
/// ```
public struct DVTextContainer<Accessories: View>: View {
    private let text: String
    private let size: DVComponentSize
    private let textColor: DVColor
    private let accessories: () -> Accessories
    /// 우측 padding (포인트). 액세서리가 있을 땐 4pt(아이콘이 약간 안쪽으로 들어오는 디자인), 액세서리 없는 단순 텍스트 컨테이너는 좌우 대칭의 8pt를 적용한다.
    private let trailingPadding: CGFloat

    /// 액세서리가 있는 텍스트 컨테이너를 생성합니다.
    ///
    /// - Parameters:
    ///   - text: 박스 좌측에 표시될 본문 텍스트. 빈 문자열을 전달하면 Empty 상태가 됩니다.
    ///   - size: 너비 변형. 기본값은 ``DVComponentSize/md``.
    ///   - textColor: 본문 텍스트 색상 토큰. 비활성 상태 등에서 다른 색을 쓰고 싶을 때 지정.
    ///     기본값 ``DVColor/gray900``.
    ///   - accessories: 박스 우측에 배치될 임의의 뷰를 만드는 빌더.
    ///   아이콘 모음, 토글 버튼 등. 버튼이 외부 `@State`를 갱신하면 자연스럽게 `text` 인자가 다음 렌더에서 바뀌어 텍스트 표시도 함께 갱신됩니다.
    public init(
        _ text: String,
        size: DVComponentSize = .md,
        textColor: DVColor = .gray900,
        @ViewBuilder accessories: @escaping () -> Accessories
    ) {
        self.text = text
        self.size = size
        self.textColor = textColor
        self.accessories = accessories
        self.trailingPadding = 4
    }

    public var body: some View {
        // spacing 8 — 텍스트(또는 가로 스크롤된 콘텐츠)와 액세서리 사이 최소 간격.
        // 텍스트가 오버플로우되어 ScrollView 우측 끝까지 스크롤되더라도 이 8pt가 보장됨.
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .font(DVFont.bodyLG.font)
                    .foregroundStyle(Color.dv(textColor))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .textSelection(.enabled)
            }
            accessories()
        }
        .padding(.leading, 8)
        .padding(.trailing, trailingPadding)
        .frame(width: size.width, height: 28, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.dv(.gray300))
        }
    }
}

extension DVTextContainer where Accessories == EmptyView {
    /// 액세서리 없는 텍스트 컨테이너를 생성합니다.
    ///
    /// 가장 흔한 사용 형태로, 단순히 한 줄 텍스트를 박스 안에 표시할 때 사용합니다.
    /// 액세서리가 없으므로 좌우 8pt 대칭 padding이 적용되어 텍스트가 박스 양 끝에서 균등하게 떨어집니다.
    ///
    /// - Parameters:
    ///   - text: 박스에 표시될 본문 텍스트.
    ///   - size: 너비 변형. 기본값은 ``DVComponentSize/md``.
    ///   - textColor: 본문 텍스트 색상 토큰. 기본값 ``DVColor/gray900``.
    public init(
        _ text: String,
        size: DVComponentSize = .md,
        textColor: DVColor = .gray900
    ) {
        self.text = text
        self.size = size
        self.textColor = textColor
        self.accessories = { EmptyView() }
        self.trailingPadding = 8
    }
}

extension DVTextContainer where Accessories == AnyView {
    /// 비밀번호 마스킹과 표시 토글 버튼이 내장된 텍스트 컨테이너를 생성합니다.
    ///
    /// Figma의 `PW_Visability` 디자인에 대응하는 편의 이니셜라이저로,
    /// 호출자는 `isRevealed` 바인딩만 제공하면 다음이 자동으로 처리됩니다:
    ///
    /// - `isRevealed == false` 일 때 텍스트가 `text.count` 길이만큼의 `•`로 마스킹되어 표시됨
    /// - `isRevealed == true` 일 때 원본 텍스트 그대로 표시됨
    /// - 우측에 눈 아이콘 토글 버튼(`eye` / `eye.slash`)이 자동 배치되어, 탭하면 `isRevealed`가 토글되고 컨테이너 표시도 즉시 갱신됨
    ///
    /// 복사와 함께 같이 보여줘야 한다면 이 편의 init 대신 일반 ``init(_:size:accessories:)``을 사용해 두 버튼을 직접 합쳐 구성하세요.
    ///
    /// ```swift
    /// @State var isPasswordVisible = false
    /// DVTextContainer(
    ///     secured: "MyP@ssword!",
    ///     isRevealed: $isPasswordVisible,
    ///     size: .md
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - text: 마스킹 대상 원본 텍스트.
    ///   - isRevealed: 마스킹 해제 여부에 대한 양방향 바인딩. 토글 버튼이 이 값을 갱신하며, 호출자도 자유롭게 외부에서 수정 가능합니다.
    ///   - size: 너비 변형. 기본값은 ``DVComponentSize/md``.
    ///   - textColor: 본문 텍스트 색상 토큰. 기본값 ``DVColor/gray900``.
    public init(
        secured text: String,
        isRevealed: Binding<Bool>,
        size: DVComponentSize = .md,
        textColor: DVColor = .gray900
    ) {
        let revealed = isRevealed.wrappedValue
        let displayed = revealed ? text : String(repeating: "•", count: text.count)
        self.init(displayed, size: size, textColor: textColor) {
            AnyView(
                Button {
                    isRevealed.wrappedValue.toggle()
                } label: {
                    Image(systemName: revealed ? "eye.slash" : "eye")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dv(.gray900))
                }
                .buttonStyle(.plain)
            )
        }
    }

    /// 복사 버튼이 내장된 텍스트 컨테이너를 생성합니다.
    ///
    /// 우측에 `doc.on.doc` SF Symbol 아이콘이 자동 배치되고, 탭하면 `onCopy` 클로저가 호출됩니다.
    /// 디자인 시스템은 클립보드 조작 로직을 직접 갖지 않으므로(레이어 분리), 실제 `NSPasteboard` 호출이나 사용자 피드백(토스트 등)은 호출자의 책임입니다.
    ///
    /// ```swift
    /// DVTextContainer(copyable: "vault-token-7af3", size: .md) {
    ///     NSPasteboard.general.clearContents()
    ///     NSPasteboard.general.setString("vault-token-7af3", forType: .string)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - text: 박스에 표시될 본문 텍스트. (호출자가 실제 클립보드에 쓸 문자열은 `onCopy` 내부에서 결정합니다 — text 인자와 다를 수 있음.)
    ///   - size: 너비 변형. 기본값은 ``DVComponentSize/md``.
    ///   - textColor: 본문 텍스트 색상 토큰. 기본값 ``DVColor/gray900``.
    ///   - onCopy: 복사 버튼 탭 시 실행될 클로저.
    public init(
        copyable text: String,
        size: DVComponentSize = .md,
        textColor: DVColor = .gray900,
        onCopy: @escaping () -> Void
    ) {
        self.init(text, size: size, textColor: textColor) {
            AnyView(
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dv(.gray900))
                }
                .buttonStyle(.plain)
            )
        }
    }

    /// 임의의 아이콘 뷰와 액션을 한 쌍으로 주입받는 단일-액세서리 컨테이너를 생성합니다.
    ///
    /// ``init(secured:isRevealed:size:)`` 나 ``init(copyable:size:onCopy:)``
    /// 같은 사전 정의 케이스에 맞지 않는 커스텀 케이스(예: 외부 링크 이동, 펼침/접기 토글, 삭제 버튼 등)를 표현할 때 사용합니다.
    /// 컨테이너는 호출자가 제공한 아이콘을 `Button`으로 자동 감싸서 일관된 hit 영역과 `.buttonStyle(.plain)` 처리를 보장합니다.
    ///
    /// 두 개 이상의 액세서리가 필요한 경우엔 이 편의 대신 기본 ``init(_:size:accessories:)`` 을 사용해 `HStack`으로 직접 구성하세요.
    ///
    /// ```swift
    /// DVTextContainer("https://example.com", size: .md, onTap: openURL) {
    ///     Image(systemName: "arrow.up.right.square")
    ///         .font(.system(size: 11))
    ///         .foregroundStyle(Color.dv(.gray900))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - text: 박스에 표시될 본문 텍스트.
    ///   - size: 너비 변형. 기본값은 ``DVComponentSize/md``.
    ///   - textColor: 본문 텍스트 색상 토큰. 기본값 ``DVColor/gray900``.
    ///   - onTap: 액세서리 버튼 탭 시 실행될 클로저.
    ///   - icon: 액세서리 자리에 표시될 아이콘 뷰를 만드는 빌더.
    public init<Icon: View>(
        _ text: String,
        size: DVComponentSize = .md,
        textColor: DVColor = .gray900,
        onTap: @escaping () -> Void,
        @ViewBuilder icon: @escaping () -> Icon
    ) {
        self.init(text, size: size, textColor: textColor) {
            AnyView(
                Button(action: onTap) {
                    icon()
                }
                .buttonStyle(.plain)
            )
        }
    }
}

// MARK: - Previews

#Preview("Filled") {
    DVTextContainer("DeVault", size: .md)
        .padding()
}

#Preview("Empty") {
    DVTextContainer("", size: .md)
        .padding()
}

#Preview("Secured (convenience init)") {
    DVTextContainerSecuredPreview()
        .padding()
}

#Preview("Copyable (convenience init)") {
    DVTextContainerCopyablePreview()
        .padding()
}

#Preview("Interactive (manual state lift)") {
    DVTextContainerInteractivePreview()
        .padding()
}

#Preview("Sizes") {
    VStack(alignment: .leading, spacing: 12) {
        DVTextContainer("XS", size: .xs)
        DVTextContainer("SM", size: .sm)
        DVTextContainer("MD", size: .md)
        DVTextContainer("LG", size: .lg)
    }
    .padding()
}

private struct DVTextContainerInteractivePreview: View {
    @State private var isRevealed = false
    private let secret = "DeVault"

    var body: some View {
        DVTextContainer(
            isRevealed ? secret : String(repeating: "•", count: secret.count),
            size: .md
        ) {
            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dv(.gray900))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct DVTextContainerSecuredPreview: View {
    @State private var isRevealed = false

    var body: some View {
        DVTextContainer(
            secured: "SuperSecret123",
            isRevealed: $isRevealed,
            size: .md
        )
    }
}

private struct DVTextContainerCopyablePreview: View {
    @State private var feedback = ""

    var body: some View {
        VStack(spacing: 8) {
            DVTextContainer(copyable: "vault-token-7af3", size: .md) {
                feedback = "복사됨"
            }
            Text(feedback)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
