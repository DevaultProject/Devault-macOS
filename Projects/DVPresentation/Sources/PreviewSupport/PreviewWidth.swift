// Copyright © 2026 Devault. All rights reserved

#if DEBUG
import SwiftUI

/// SwiftUI Preview 편의를 위한 너비 프리셋 (macOS NavigationSplitView 기준).
/// 각 `#Preview` 블록에서 하나씩 골라 `previewWidth(_:)`로 붙인다.
///
/// `FormLayoutMode.dualThreshold`(828pt)와 정합적으로 배치 — narrow/medium은 single 모드,
/// wide/extraWide는 dual 모드를 자연스럽게 트리거한다.
///
/// ```swift
/// #Preview("Narrow · 440pt") {
///     CreateSecretView(store: ...).previewWidth(.narrow)
/// }
/// ```
enum PreviewWidth: CGFloat {

    /// single 모드 최소 폭. `.md`(380) + horizontal padding(24×2)이 여유 있게 들어가는 최소치.
    case narrow = 540

    /// single 모드 표준 폭.
    case medium = 700

    /// dual 모드 최소 폭. `FormLayoutMode.dualThreshold`(828pt) 위.
    case wide = 900

    /// dual 모드 최대 확장 폭.
    case extraWide = 1200
}

extension View {

    /// Preview 캔버스의 컨텐츠 너비를 프리셋으로 고정.
    func previewWidth(_ preset: PreviewWidth) -> some View {
        frame(width: preset.rawValue, alignment: .top)
    }

    /// Preview 캔버스의 컨텐츠 너비를 임의 값으로 고정.
    func previewWidth(_ width: CGFloat) -> some View {
        frame(width: width, alignment: .top)
    }
}
#endif
