// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 여러 줄 값을 **표시만** 하는 읽기 전용 컨테이너. ``DVMultilineTextField``의 read-only counterpart.
///
/// ``DVTextField``↔``DVTextContainer``와 같은 관계다. 다만 ``DVTextContainer``가 한 줄만 보여주는 것과 달리,
/// 개행이 포함된 값(PEM 블록, JSON, `KEY=value` 목록 등)을 **줄 구조 그대로 전부** 노출한다.
///
/// ## 시각 상태
///
/// | 상태 | 설명 |
/// |------|------|
/// | Filled | 본문 텍스트가 ``DVColor/gray900`` 으로 여러 줄 표시 |
/// | Empty | `text == ""` — 박스만 보이고 콘텐츠 없음 |
/// | hasAccessories | 우측 상단에 **인터랙티브** 액세서리(복사·표시 토글 등) 배치 |
///
/// 배경(``DVColor/gray300``)·corner radius·좌우 padding·본문 폰트(``DVFont/bodyLG``)는
/// ``DVTextContainer``와 **같은 값**이다. 한 화면에서 한 줄 필드와 여러 줄 필드가 섞여도 두 박스가
/// 같은 계열로 읽혀야 하기 때문이다.
///
/// ## 높이
///
/// 너비는 ``DVComponentSize``, 높이는 `height`로 **고정**한다 — ``DVMultilineTextField``와 같은 정책이며
/// 기본값(100pt)도 같다. 값 길이에 따라 박스가 늘어나면 폼의 행 높이가 데이터마다 달라지므로 고정한다.
///
/// ## 오버플로우 처리
///
/// 내용이 `height`를 넘으면 **세로 스크롤**된다. 긴 줄은 컨테이너 폭에서 접히므로(soft wrap)
/// 가로 스크롤은 쓰지 않는다 — 두 축을 모두 조작해야 값 전체를 확인할 수 있는 상황을 만들지 않기 위해서다.
///
/// 스크롤 인디케이터는 ``DVTextContainer``와 달리 **표시한다**. 이 컴포넌트가 존재하는 이유 자체가
/// "가려진 내용을 인지할 수 없다"는 문제이므로, 더 볼 것이 있다는 신호를 지우면 안 된다.
/// macOS overlay scroller라 스크롤·호버 시에만 나타나 평소 시각적 비용은 없다.
///
/// ## 텍스트 선택·복사
///
/// 본문에 `.textSelection(.enabled)`이 적용되어 있어 드래그·⌘+C로 원하는 구간만 복사할 수 있다.
/// 세로 스크롤로 가려진 부분도 드래그를 이어가며 선택 가능하다.
///
/// ## 액세서리
///
/// 액세서리는 우측 **상단**에 고정된다. 근거는 세 가지다:
///
/// 1. 박스가 100pt 안팎으로 높아, 세로 중앙에 두면 버튼이 본문 한가운데에 떠서 특정 줄에 걸린 것처럼 보인다.
/// 2. 본문을 스크롤해도 버튼이 움직이지 않아 위치를 다시 찾을 필요가 없다.
/// 3. 값이 짧든 길든 버튼이 항상 같은 자리에 있어, 여러 필드가 세로로 쌓였을 때 액세서리 열이 흔들리지 않는다.
///
/// 마스킹·클립보드 같은 동작은 컨테이너가 갖지 않는다 — ``DVTextContainer``와 마찬가지로
/// 호출자가 `text`의 source of truth를 소유하고 컨테이너는 그 값을 그릴 뿐이다(상태 끌어올리기).
///
/// ## 사용
///
/// ```swift
/// // 단순 표시 (액세서리 없음)
/// DVMultilineTextContainer(pemBlock, size: .md)
///
/// // 마스킹 토글 + 복사 버튼을 직접 구성
/// @State var isRevealed = false
/// DVMultilineTextContainer(isRevealed ? value : masked, size: .md) {
///     HStack(spacing: 10) {
///         Button { copy(value) } label: { Image(systemName: "doc.on.doc") }
///         Button { isRevealed.toggle() } label: {
///             Image(systemName: isRevealed ? "eye.slash" : "eye")
///         }
///     }
///     .font(.system(size: 11))
///     .foregroundStyle(Color.dv(.gray900))
///     .buttonStyle(.plain)
/// }
/// ```
// MARK: - Metrics

/// ``DVMultilineTextContainer``의 레이아웃 상수.
/// 제네릭 타입 안에 중첩하면 이 enum도 제네릭이 되어 static stored property를 가질 수 없다 —
/// ``DVMultiSelectDropdown``의 `DropdownMetrics`와 같은 이유로 파일 스코프에 둔다.
fileprivate enum MultilineContainerMetrics {
    static let cornerRadius: CGFloat = 6
    static let leadingPadding: CGFloat = 8

    /// 본문과 액세서리 사이 최소 간격. ``DVTextContainer``와 같은 값.
    static let contentSpacing: CGFloat = 8

    /// 상하 padding. ``DVTextContainer``의 28pt 박스에서 ``DVFont/bodyLG`` 한 줄이 갖는 여백
    /// `(28 - bodyLG.lineHeight) / 2`와 같아, 첫 줄이 한 줄 컨테이너와 같은 높이에서 시작한다.
    static let verticalPadding: CGFloat = 6
}

public struct DVMultilineTextContainer<Accessories: View>: View {

    private typealias Metrics = MultilineContainerMetrics

    // MARK: - Properties

    private let text: String
    private let size: DVComponentSize
    private let height: CGFloat
    private let textColor: DVColor
    private let accessories: () -> Accessories

    /// 우측 padding (포인트). ``DVTextContainer``와 같은 규칙 — 액세서리가 있으면 4pt,
    /// 없으면 좌우 대칭의 8pt.
    private let trailingPadding: CGFloat

    // MARK: - Init

    /// 액세서리가 있는 여러 줄 텍스트 컨테이너를 생성합니다.
    ///
    /// - Parameters:
    ///   - text: 박스에 표시될 본문. 개행이 그대로 유지되며, 긴 줄은 컨테이너 폭에서 접힙니다.
    ///     빈 문자열을 전달하면 Empty 상태가 됩니다.
    ///   - size: 너비 변형. 기본값 ``DVComponentSize/md``.
    ///   - height: 고정 높이. 기본값 100pt — ``DVMultilineTextField``와 같은 값입니다.
    ///     내용이 이 높이를 넘으면 내부에서 세로 스크롤됩니다.
    ///   - textColor: 본문 텍스트 색상 토큰. 기본값 ``DVColor/gray900``.
    ///   - accessories: 박스 우측 상단에 배치될 뷰를 만드는 빌더. 버튼이 외부 `@State`를 갱신하면
    ///     다음 렌더에서 `text` 인자가 바뀌어 본문 표시도 함께 갱신됩니다.
    public init(
        _ text: String,
        size: DVComponentSize = .md,
        height: CGFloat = 100,
        textColor: DVColor = .gray900,
        @ViewBuilder accessories: @escaping () -> Accessories
    ) {
        self.text = text
        self.size = size
        self.height = height
        self.textColor = textColor
        self.accessories = accessories
        self.trailingPadding = 4
    }

    // MARK: - Body

    public var body: some View {
        HStack(alignment: .top, spacing: Metrics.contentSpacing) {
            scrollingText
            accessories()
        }
        .padding(.leading, Metrics.leadingPadding)
        .padding(.trailing, trailingPadding)
        .padding(.vertical, Metrics.verticalPadding)
        .dvComponentWidth(size, height: height, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .fill(Color.dv(.gray300))
        }
    }
}

// MARK: - Subviews

extension DVMultilineTextContainer {

    private var scrollingText: some View {
        ScrollView(.vertical) {
            Text(text)
                .font(DVFont.bodyLG.font)
                .foregroundStyle(Color.dv(textColor))
                .lineSpacing(DVFont.bodyLG.lineSpacing)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Convenience Init

extension DVMultilineTextContainer where Accessories == EmptyView {

    /// 액세서리 없는 여러 줄 텍스트 컨테이너를 생성합니다.
    ///
    /// 액세서리가 없으므로 좌우 8pt 대칭 padding이 적용되어 본문이 박스 양 끝에서 균등하게 떨어집니다.
    ///
    /// - Parameters:
    ///   - text: 박스에 표시될 본문.
    ///   - size: 너비 변형. 기본값 ``DVComponentSize/md``.
    ///   - height: 고정 높이. 기본값 100pt.
    ///   - textColor: 본문 텍스트 색상 토큰. 기본값 ``DVColor/gray900``.
    public init(
        _ text: String,
        size: DVComponentSize = .md,
        height: CGFloat = 100,
        textColor: DVColor = .gray900
    ) {
        self.text = text
        self.size = size
        self.height = height
        self.textColor = textColor
        self.accessories = { EmptyView() }
        self.trailingPadding = 8
    }
}

// MARK: - Previews

#if DEBUG

#Preview("한 줄 값") {
    DVMultilineTextContainer("DeVault", size: .md)
        .padding()
}

#Preview("여러 줄 값") {
    DVMultilineTextContainer(
        """
        DATABASE_URL=postgres://user:pass@localhost:5432/mydb
        SECRET_KEY=abc123
        """,
        size: .md
    )
    .padding()
}

#Preview("높이 초과 · 세로 스크롤") {
    DVMultilineTextContainer(DVMultilineTextContainerPreviewData.overflowing, size: .md)
        .padding()
}

#Preview("Empty") {
    DVMultilineTextContainer("", size: .md)
        .padding()
}

#Preview("Accessories") {
    DVMultilineTextContainerAccessoriesPreview()
        .padding()
}

#Preview("Sizes") {
    VStack(alignment: .leading, spacing: 12) {
        DVMultilineTextContainer("XS\nsecond line", size: .xs, height: 80)
        DVMultilineTextContainer("SM\nsecond line", size: .sm, height: 80)
        DVMultilineTextContainer("MD\nsecond line", size: .md, height: 80)
        DVMultilineTextContainer("LG\nsecond line", size: .lg)
    }
    .padding()
}

private enum DVMultilineTextContainerPreviewData {
    /// 고정 높이(100pt)를 넘겨 세로 스크롤을 유도하는 값.
    ///
    /// 개인키 형태의 문자열은 쓰지 않는다 — 값이 가짜여도 시크릿 스캐너가 탐지 결과를 올려서,
    /// 이 파일을 건드리는 모든 PR에 같은 지적이 반복된다.
    static let overflowing = """
    DATABASE_URL=postgres://user:pass@localhost:5432/mydb
    REDIS_URL=redis://localhost:6379/0
    SMTP_HOST=smtp.example.com
    SMTP_PORT=587
    LOG_LEVEL=debug
    FEATURE_SYNC_ENABLED=true
    RETRY_BACKOFF_SECONDS=30
    """
}

private struct DVMultilineTextContainerAccessoriesPreview: View {
    @State private var isRevealed = false

    private let value = """
    DATABASE_URL=postgres://user:pass@localhost:5432/mydb
    SECRET_KEY=abc123
    """

    /// 여러 줄 값의 마스킹은 줄 단위로 `•`를 채워 줄 구조를 남기는 것이 호출부 권장 패턴이다.
    private var masked: String {
        value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String(repeating: "•", count: $0.count) }
            .joined(separator: "\n")
    }

    var body: some View {
        DVMultilineTextContainer(isRevealed ? value : masked, size: .md) {
            HStack(spacing: 10) {
                Button(action: {}) {
                    Image(systemName: "doc.on.doc")
                }
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(Color.dv(.gray900))
            .buttonStyle(.plain)
        }
    }
}

#endif
