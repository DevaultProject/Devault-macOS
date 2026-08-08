// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 폼이 놓인 **화면 맥락**. 컨테이너 폭 → `FormLayout` 해석 규칙을 소유한다.
///
/// 화면 맥락(단일 화면 / detail 컬럼)과 배열 상태(1열 / 2열)는 축이 다르다 —
/// 맥락은 화면이 정해주는 정적 성질이고, 배열은 폭에서 파생되는 동적 결과다.
/// 그래서 `FormLayout`에 `.detail` 케이스를 추가하는 대신 두 축을 분리한다.
///
/// 임계값과 사이즈 매핑은 **전부 채택 타입 안에** 있으므로, 새 맥락이 생겨도
/// 기존 맥락의 수치를 건드리지 않는다.
protocol FormLayoutContext {

    /// 컨테이너 폭에 대응하는 배열.
    static func layout(for containerWidth: CGFloat) -> FormLayout
}

// MARK: - Standalone (CreateSecret)

/// 폼이 창 전체를 쓰는 **단일 화면** 맥락 — CreateSecret.
///
/// 사이즈는 항상 고정(`DVComponentSize` 그대로)이다. 좁아지면 2열 폼이 1열로 접히고
/// full-width 필드가 `.lg` → `.md`로 줄어든다.
enum StandaloneFormLayout: FormLayoutContext {

    static func layout(for containerWidth: CGFloat) -> FormLayout {
        containerWidth >= FormLayoutMetrics.dualThreshold ? .dual : .single
    }
}

// MARK: - Detail column (SecretDetail)

/// NavigationSplitView **detail 컬럼**에 놓이는 폼 맥락 — SecretDetail (2분할 화면).
///
/// 단일 화면과 다른 점은 **임계값 아래에서의 배열**이다:
/// - 단일 화면은 고정 `.md` + 페어를 세로로 접음
/// - detail 컬럼은 컨테이너를 채우고 페어를 절반씩 가로 유지 (Figma `1768:30806`)
///
/// detail 컬럼은 폭 상한이 없다(`navigationSplitViewColumnWidth(min: 420, ideal: 480)`).
/// sidebar(최대 270) + list(최대 350)가 620으로 상한이 있어 `detail ≈ 윈도우 − 620`이므로,
/// 넓은 디스플레이에서는 2열 폼 임계값(816)을 넘는다 — 그때는 단일 화면과 같은 `.dual` 배열을 쓴다.
enum DetailColumnFormLayout: FormLayoutContext {

    static func layout(for containerWidth: CGFloat) -> FormLayout {
        containerWidth >= FormLayoutMetrics.dualThreshold ? .dual : .detailFluid
    }
}
