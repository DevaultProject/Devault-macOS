// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

// MARK: - FormSlotSize

/// 각 폼 필드가 폼 안에서 차지하는 슬롯. `FormLayout`과 결합해 실 컴포넌트 사이즈로 매핑된다.
enum FormSlotSize: Equatable {
    /// 행 전체를 차지하는 필드 (Name, Value, Memo 등).
    case fullWidth
    /// 2-col row 안의 한 칸을 차지하는 필드.
    case paired
}

// MARK: - FormLayoutMetrics

/// 폼 배열에 쓰이는 수치의 단일 정의부. 임계값이 이 상수들로부터 계산된다.
enum FormLayoutMetrics {

    /// 폼 콘텐츠 좌우 padding.
    static let horizontalPadding: CGFloat = 20

    /// 폼 콘텐츠 상하 padding. 현재 좌우와 같은 값이지만 임계값 계산에는 쓰이지 않으므로
    /// 별도 상수로 둔다 — 좌우 padding을 조정할 때 세로 여백이 끌려가면 안 된다.
    static let verticalPadding: CGFloat = 20

    /// 필드 행 사이 세로 간격.
    static let rowSpacing: CGFloat = 16

    /// 2열 폼에서 페어 슬롯 사이 간격.
    static let dualPairSpacing: CGFloat = 16

    /// Detail 가변 폼에서 페어 슬롯 사이 간격 (Figma `1768:30828` 실측 — `x=0`, `x=200`, 폭 180).
    static let detailPairSpacing: CGFloat = 20

    /// 2열 폼으로 전환하는 컨테이너 폭 하한.
    ///
    /// 계산: `2 × md(380) + dualPairSpacing(16) + horizontalPadding × 2` = **816**.
    /// 페어 두 칸을 `.md`로 나란히 놓을 수 있게 되는 지점이다.
    static let dualThreshold: CGFloat =
        2 * DVComponentSize.md.width + dualPairSpacing + horizontalPadding * 2

    /// 2열 폼의 콘텐츠 폭 — 가장 넓은 행(페어 2칸)의 폭.
    ///
    /// 계산: `2 × md(380) + dualPairSpacing(16)` = **776**.
    /// full-width 필드(`.lg` 700)보다 페어 행이 더 넓으므로 이쪽이 콘텐츠 폭을 지배한다.
    static let dualContentWidth: CGFloat =
        2 * DVComponentSize.md.width + dualPairSpacing

    /// **폼 화면 전체 프레임의 최대 폭.**
    ///
    /// 계산: `dualContentWidth(776) + horizontalPadding × 2` = **816**.
    /// 2열 폼이 가장 넓은 배열이므로 그 이상으로 넓어질 필요가 없다.
    /// `dualThreshold`와 같은 값인 것은 우연이 아니다 — 같은 식에서 나온다.
    ///
    /// 이 상한이 없으면 본문 필드는 제자리인데 footer 버튼만 창 오른쪽 끝까지 밀려나
    /// 시선 이동이 과해진다. 프레임을 제한하면 header · 본문 · footer가 **각자 프레임을 따라가면서도**
    /// 좌우 끝이 함께 멈춘다.
    static let maxFormWidth: CGFloat = dualContentWidth + horizontalPadding * 2
}

// MARK: - FormLayout

/// 컨테이너 폭까지 반영해 **이미 해석된** 폼 배열.
///
/// 필드 뷰와 row 래퍼는 이 값만 읽는다 — 임계값이나 화면 맥락(단일 화면 / detail 컬럼)을 알지 못한다.
/// 어떤 배열을 쓸지는 `FormLayoutContext` 채택 타입이 결정한다.
struct FormLayout: Equatable {

    /// 페어 슬롯 두 개의 배치 축.
    enum PairAxis: Equatable {
        /// 가로 2열. `spacing`은 두 슬롯 사이 간격.
        case horizontal(spacing: CGFloat)
        /// 세로 1열로 접힘.
        case vertical(spacing: CGFloat)
    }

    /// full-width 슬롯 사이즈. `widthPolicy == .fill`이면 **최소 폭**으로 동작한다.
    var fullWidthSize: DVComponentSize
    /// 페어 슬롯 사이즈. `widthPolicy == .fill`이면 **최소 폭**으로 동작한다.
    var pairedSize: DVComponentSize
    var pairAxis: PairAxis
    var rowSpacing: CGFloat
    /// 슬롯 폭 해석 정책. `.fill`이면 컴포넌트가 컨테이너를 채운다.
    ///
    /// `.fill`의 성장 상한은 화면 루트의 `FormLayoutMetrics/maxFormWidth` 프레임 제한이 담당한다 —
    /// 배열이 따로 상한을 갖지 않는다.
    var widthPolicy: DVComponentWidthPolicy

    func size(for slot: FormSlotSize) -> DVComponentSize {
        switch slot {
        case .fullWidth: return fullWidthSize
        case .paired:    return pairedSize
        }
    }
}

// MARK: - Presets

extension FormLayout {

    /// 2열 폼 — 페어 두 칸을 나란히 놓고 프레임을 채운다.
    ///
    /// CreateSecret의 넓은 폭 배열이며, **Detail 컬럼도 충분히 넓어지면 같은 배열을 쓴다** —
    /// 두 화면이 같은 모습이 되는 것은 의도된 동작이다.
    ///
    /// `widthPolicy`가 `.fill`이라 사이즈는 **최소 폭**으로만 쓰인다. 프레임 상한(`maxFormWidth` 816,
    /// 콘텐츠 776)에서 full-width는 776, 페어는 `(776 - 16) / 2 = 380 = .md`가 되어 정확히 맞물린다.
    ///
    /// `.fixed`로 두면 full-width가 `.lg`(700)에 머물러 페어 행(776)보다 좁아 **오른쪽 끝이 들쭉날쭉**해지고,
    /// `.detailFluid`에서 넘어올 때 필드가 775 → 700으로 줄어드는 역전이 생긴다.
    static let dual = FormLayout(
        fullWidthSize: .lg,
        pairedSize: .md,
        pairAxis: .horizontal(spacing: FormLayoutMetrics.dualPairSpacing),
        rowSpacing: FormLayoutMetrics.rowSpacing,
        widthPolicy: .fill
    )

    /// 1열 폼 — full-width `.md`, 페어는 세로로 접힘. CreateSecret의 좁은 폭 배열.
    static let single = FormLayout(
        fullWidthSize: .md,
        pairedSize: .md,
        pairAxis: .vertical(spacing: FormLayoutMetrics.rowSpacing),
        rowSpacing: FormLayoutMetrics.rowSpacing,
        widthPolicy: .fixed
    )

    /// 가변 폭 1열 폼 — 컨테이너를 채우고 페어는 절반씩 나눈다. Detail 컬럼의 기본 배열.
    ///
    /// 사이즈는 최소 폭으로만 쓰인다. 콘텐츠 380(컬럼 최소 420)에서 페어는 `(380 - 20) / 2 = 180 = .xs`,
    /// 콘텐츠 776(프레임 상한 816)에서 각각 378이 되고 거기서 멈춘다.
    static let detailFluid = FormLayout(
        fullWidthSize: .md,
        pairedSize: .xs,
        pairAxis: .horizontal(spacing: FormLayoutMetrics.detailPairSpacing),
        rowSpacing: FormLayoutMetrics.rowSpacing,
        widthPolicy: .fill
    )
}

// MARK: - Environment

extension EnvironmentValues {

    /// 현재 폼 배열. 화면 루트가 `FormLayoutContext`로 해석해 `formLayout(_:)`으로 주입한다.
    @Entry var formLayout: FormLayout = .dual
}

extension View {

    /// 폼 배열과 그에 대응하는 컴포넌트 폭 정책을 **함께** 주입한다.
    ///
    /// `widthPolicy`를 따로 주입하는 것을 잊으면 `.fill` 배열에서 컴포넌트가 고정 폭으로 남아
    /// 조용히 어긋나므로, 두 값을 항상 한 번에 설정한다.
    func formLayout(_ layout: FormLayout) -> some View {
        environment(\.formLayout, layout)
            .environment(\.dvComponentWidthPolicy, layout.widthPolicy)
    }

    /// 폼 화면 전체 프레임의 최대 폭을 적용하고 leading 정렬한다.
    ///
    /// 화면 루트(header + 본문 + footer를 감싸는 컨테이너)에 **한 번만** 적용한다.
    /// header/footer는 본문과 분리된 채 각자 이 프레임을 따라가면 된다.
    func formMaxWidth() -> some View {
        frame(maxWidth: FormLayoutMetrics.maxFormWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
