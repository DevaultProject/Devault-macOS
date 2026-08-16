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
/// | hasLeadingIcon | 좌측에 **비인터랙티브** 아이콘 배치. 값의 성격을 알리는 표지 |
///
/// 외곽선은 없고 ``DVColor/gray300`` 배경 채움으로 박스 형태를 표현합니다.
///
/// ## 높이와 줄바꿈
///
/// 높이는 ``DVComponentSize/fieldHeight``를 **최소값**으로 갖고, 내용이 많으면 그만큼 자랍니다.
/// 본문이 폭을 넘으면 잘리거나 가로 스크롤되지 않고 **다음 줄로 접힙니다**. 개행이 있는 값
/// (PEM, JSON, `KEY=value` 목록)도 줄 구조 그대로 전부 보입니다.
///
/// 접히는 단위는 단어가 아니라 **글자**입니다. 이 컨테이너가 다루는 값은 인증서·키·JSON·명령어처럼
/// 단어 경계가 의미 없는 기계값이라, 단어 단위로 접으면 오른쪽에 큰 여백이 남아 상자가 실제보다
/// 좁아 보입니다. 공백이 의미를 갖는 값도 단어 중간에서 접히는 것이 이 선택의 대가입니다.
///
/// 읽기 전용 표시라 값을 확인할 다른 수단이 없으므로, 스크롤 조작을 요구하는 대신 다 펼쳐 보여줍니다.
/// 그래서 ``DVTextField``(입력)의 가로 시프트 동작과는 다릅니다 — 입력은 커서를 따라가야 하지만
/// 표시는 전체를 한눈에 보여주는 쪽이 맞습니다.
///
/// 본문과 액세서리 사이에는 **최소 8pt 간격**이 보장되어 글자가 액세서리 버튼에 들러붙지 않습니다.
/// 여러 줄로 자라도 액세서리와 leading 아이콘은 **상단에 고정**되어 특정 줄에 걸친 것처럼 보이지 않습니다.
///
/// ## 텍스트 선택·복사
///
/// 본문을 마우스로 드래그해 선택하고 ⌘+C로 클립보드에 복사할 수 있습니다.
/// ``init(copyable:size:onCopy:)`` 편의 init과 별도로 동작하므로 둘 다 함께 활용 가능합니다.
///
/// ## 액세서리
///
/// 액세서리는 항상 **인터랙티브**(`Button` 기반)로 사용한다는 전제로 설계되었습니다.
/// 단순 장식용 아이콘은 ``DVTextContainer``의 디자인 의도가 아니므로 사용하지 않습니다.
/// 액세서리 액션은 외부 `@State`나 콜백을 통해 컨테이너에 표시되는 `text`에 영향을 주는 식으로 연결됩니다.
///
/// ## Leading 아이콘
///
/// 값 자체의 성격을 알리는 비인터랙티브 아이콘은 `leadingIcon`으로 본문 **왼쪽**에 놓습니다
/// (예: 만료가 임박한 날짜 앞의 경고 표지). 색은 `textColor`를 그대로 따라가므로
/// 아이콘과 본문이 항상 같은 색으로 그려집니다 — 둘의 색이 갈리는 조합을 만들 수 없습니다.
///
/// 탭 가능한 아이콘은 leading이 아니라 액세서리 슬롯의 것입니다. 두 슬롯을 혼동하면
/// 인터랙션 가능 여부가 위치로 드러나지 않게 됩니다.
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
/// // 값 왼쪽에 표지 아이콘 (아이콘 색은 textColor를 따라감)
/// DVTextContainer(
///     "26.04.07",
///     size: .md,
///     textColor: .danger,
///     leadingIcon: Image(systemName: "exclamationmark.triangle")
/// )
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
    /// 본문 왼쪽에 놓이는 비인터랙티브 표지 아이콘. 본문이 여러 줄로 자라도 첫 줄에 붙어 있는다.
    private let leadingIcon: Image?
    private let accessories: () -> Accessories
    /// 우측 padding (포인트). 액세서리가 있을 땐 4pt(아이콘이 약간 안쪽으로 들어오는 디자인), 액세서리 없는 단순 텍스트 컨테이너는 좌우 대칭의 8pt를 적용한다.
    private let trailingPadding: CGFloat

    /// 액세서리가 있는 텍스트 컨테이너를 생성합니다.
    ///
    /// - Parameters:
    ///   - text: 박스 좌측에 표시될 본문 텍스트. 빈 문자열을 전달하면 Empty 상태가 됩니다.
    ///   - size: 너비 변형. 기본값은 ``DVComponentSize/md``.
    ///   - textColor: 본문 텍스트 색상 토큰. 비활성 상태 등에서 다른 색을 쓰고 싶을 때 지정.
    ///     기본값 ``DVColor/gray900``. `leadingIcon`에도 같은 색이 적용됩니다.
    ///   - leadingIcon: 본문 왼쪽에 놓을 비인터랙티브 표지 아이콘. 기본값 `nil`.
    ///   - accessories: 박스 우측에 배치될 임의의 뷰를 만드는 빌더.
    ///   아이콘 모음, 토글 버튼 등. 버튼이 외부 `@State`를 갱신하면 자연스럽게 `text` 인자가 다음 렌더에서 바뀌어 텍스트 표시도 함께 갱신됩니다.
    public init(
        _ text: String,
        size: DVComponentSize = .md,
        textColor: DVColor = .gray900,
        leadingIcon: Image? = nil,
        @ViewBuilder accessories: @escaping () -> Accessories
    ) {
        self.text = text
        self.size = size
        self.textColor = textColor
        self.leadingIcon = leadingIcon
        self.accessories = accessories
        self.trailingPadding = 4
    }

    public var body: some View {
        // 본문이 여러 줄로 자랄 수 있으므로 상단 정렬 — 액세서리와 leading 아이콘이
        // 박스 세로 중앙으로 밀려 특정 줄에 걸친 것처럼 보이면 안 된다.
        HStack(alignment: .top, spacing: 8) {
            // leading 아이콘은 본문과 한 덩어리로 읽히도록 액세서리보다 좁은 6pt로 붙인다.
            HStack(alignment: .top, spacing: 6) {
                leadingIconView
                CharacterWrappingText(text, textColor: textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            accessories()
        }
        .padding(.leading, 8)
        .padding(.trailing, trailingPadding)
        .padding(.vertical, Self.verticalPadding)
        .dvComponentWidth(size, minHeight: DVComponentSize.fieldHeight, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.dv(.gray300))
        }
    }

    /// 상하 padding. 한 줄일 때 박스가 정확히 ``DVComponentSize/fieldHeight``가 되도록 잡는다.
    /// 높이가 고정에서 최소로 바뀌었으므로 세로 중앙 정렬 대신 이 값이 첫 줄 위치를 결정한다.
    private static var verticalPadding: CGFloat {
        (DVComponentSize.fieldHeight - DVFont.bodyLG.lineHeight) / 2
    }

    /// 본문과 같은 폰트를 써서 아이콘이 글자 크기에 맞춰 따라가고, `fixedSize()`로
    /// 본문이 오버플로우될 때 눌려 찌그러지지 않게 한다.
    @ViewBuilder
    private var leadingIconView: some View {
        if let leadingIcon {
            leadingIcon
                .font(DVFont.bodyLG.font)
                .foregroundStyle(Color.dv(textColor))
                .fixedSize()
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
    ///   - leadingIcon: 본문 왼쪽에 놓을 비인터랙티브 표지 아이콘. `textColor`와 같은 색으로 그려집니다. 기본값 `nil`.
    public init(
        _ text: String,
        size: DVComponentSize = .md,
        textColor: DVColor = .gray900,
        leadingIcon: Image? = nil
    ) {
        self.text = text
        self.size = size
        self.textColor = textColor
        self.leadingIcon = leadingIcon
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

// MARK: - Character wrapping

/// 본문을 **글자 단위로** 접어 그리는 텍스트. 선택·복사는 그대로 된다.
///
/// AppKit으로 내려오는 이유는 SwiftUI `Text`가 단어 단위로만 접히고 wrap 모드를 여는 API가 없기
/// 때문이다. 글자 단위로 접는 이유 자체는 ``DVTextContainer``의 "높이와 줄바꿈"에 있다.
///
/// `NSTextField`가 아니라 `NSTextView`를 쓰는 이유는 **높이를 정확히 재기 위해서**다. 컨테이너
/// 인셋과 line fragment padding을 0으로 두고 실제로 그리는 레이아웃 매니저에게 높이를 물으므로,
/// 측정값과 그리는 폭이 어긋나 마지막 글자가 한 줄 더 밀리는 일이 없다.
private struct CharacterWrappingText: NSViewRepresentable {

    private let text: String
    private let textColor: DVColor

    init(_ text: String, textColor: DVColor) {
        self.text = text
        self.textColor = textColor
    }

    private static let font = DVFont.bodyLG

    private var attributed: NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byCharWrapping
        paragraph.lineSpacing = Self.font.lineSpacing
        return NSAttributedString(
            string: text,
            attributes: [
                .font: Self.font.nsFont,
                .foregroundColor: textColor.nsColor,
                .paragraphStyle: paragraph,
            ]
        )
    }

    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView()
        view.isEditable = false
        view.isSelectable = true
        view.drawsBackground = false
        view.isRichText = false
        // 인셋을 0으로 둬야 측정한 높이와 그리는 높이가 같다.
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.textContainer?.widthTracksTextView = true
        view.isHorizontallyResizable = false
        view.isVerticallyResizable = true
        return view
    }

    func updateNSView(_ view: NSTextView, context: Context) {
        view.textStorage?.setAttributedString(attributed)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }
        // 측정 전에 내용을 맞춰둔다 — `updateNSView`보다 먼저 불릴 수 있다.
        nsView.textStorage?.setAttributedString(attributed)
        guard let container = nsView.textContainer, let layout = nsView.layoutManager else {
            return nil
        }
        container.containerSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        layout.ensureLayout(for: container)
        // 빈 값이어도 한 줄 높이는 차지해야 상자 높이가 값 유무에 따라 튀지 않는다.
        let height = max(layout.usedRect(for: container).height, Self.font.lineHeight)
        return CGSize(width: width, height: ceil(height))
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Filled") {
    DVTextContainer("DeVault", size: .md)
        .padding()
}

#Preview("Empty") {
    DVTextContainer("", size: .md)
        .padding()
}

#Preview("Leading icon") {
    VStack(alignment: .leading, spacing: 12) {
        DVTextContainer(
            "26.04.07",
            size: .md,
            textColor: .danger,
            leadingIcon: DVExpiryEmphasis.danger.icon
        )
        DVTextContainer(
            "26.04.11",
            size: .md,
            textColor: .warning,
            leadingIcon: DVExpiryEmphasis.warning.icon
        )
    }
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

#Preview("Character wrapping") {
    VStack(alignment: .leading, spacing: 12) {
        DVTextContainer(
            "Server=db.internal.example.com; Port=5432; Database=vault_prod; "
                + "User Id=svc_reader; Timeout=30",
            size: .md
        )
        DVTextContainer(
            "-----BEGIN PRIVATE KEY-----MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcw"
                + "ggSjAgEAAoIBAQC7VJTUt9Us8cKjMzEfYyjiWA4R4/M2bS1GB4t7NXp98C3SC6dV",
            size: .md
        )
    }
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

#endif
