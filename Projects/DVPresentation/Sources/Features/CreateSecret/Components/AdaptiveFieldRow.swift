// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// `FormLayoutMode`에 따라 두 필드를 2-column HStack ↔ 1-column VStack으로 전환하는 래퍼.
///
/// dual 모드: `HStack(spacing: 20)`으로 좌·우 필드 나란히.
/// single 모드: `VStack(spacing: 20)`으로 위·아래 필드 스택.
///
/// ```swift
/// AdaptiveFieldRow {
///     ProjectFieldView(...)
/// } right: {
///     ServicesFieldView(...)
/// }
/// ```
struct AdaptiveFieldRow<Left: View, Right: View>: View {

    @Environment(\.formLayoutMode) private var mode

    private let left: () -> Left
    private let right: () -> Right

    init(
        @ViewBuilder left: @escaping () -> Left,
        @ViewBuilder right: @escaping () -> Right
    ) {
        self.left = left
        self.right = right
    }

    var body: some View {
        switch mode {
        case .dual:
            HStack(alignment: .top, spacing: 20) {
                left()
                right()
            }
        case .single:
            VStack(alignment: .leading, spacing: 20) {
                left()
                right()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Dual mode · wide") {
    AdaptiveFieldRow {
        SamplePlaceholder(label: "Left", color: .blue)
    } right: {
        SamplePlaceholder(label: "Right", color: .green)
    }
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Single mode · narrow") {
    AdaptiveFieldRow {
        SamplePlaceholder(label: "Left", color: .blue)
    } right: {
        SamplePlaceholder(label: "Right", color: .green)
    }
    .padding(24)
    .environment(\.formLayoutMode, .single)
    .previewWidth(.narrow)
}

private struct SamplePlaceholder: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .frame(maxWidth: .infinity, minHeight: 28)
            .padding(.horizontal, 8)
            .background(color.opacity(0.15))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(color.opacity(0.4)))
    }
}

#endif
