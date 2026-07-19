// Copyright © 2026 Devault. All rights reserved

#if DEBUG
import SwiftUI

/// SwiftUI Preview 편의를 위한 너비 프리셋 (macOS NavigationSplitView 기준).
/// 각 `#Preview` 블록에서 하나씩 골라 `previewWidth(_:)`로 붙인다.
///
/// ```swift
/// #Preview("Narrow · 360pt") {
///     CreateSecretView(store: ...).previewWidth(.narrow)
/// }
/// #Preview("Medium · 560pt") {
///     CreateSecretView(store: ...).previewWidth(.medium)
/// }
/// ```
enum PreviewWidth: CGFloat {

    /// 사이드바 + inspector 모두 열린 상태의 좁은 detail 폭.
    case narrow = 360

    /// 표준 detail 폭.
    case medium = 560

    /// 사이드바만 열린 상태의 넓은 detail 폭.
    case wide = 820

    /// 사이드바/inspector 모두 닫힌 최대 확장 폭.
    case extraWide = 1100
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
