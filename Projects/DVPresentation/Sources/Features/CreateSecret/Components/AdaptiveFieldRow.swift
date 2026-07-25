// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// `FormLayoutMode`에 따라 두 필드를 2-column HStack ↔ 1-column VStack으로 전환하는 래퍼.
///
/// dual 모드: `HStack(spacing: 16)`으로 좌·우 필드 나란히.
/// single 모드: `VStack(spacing: 16)`으로 위·아래 필드 스택.
///
/// 슬롯 중 하나만 있는 1-arg 형태도 지원 — dual에선 비어있는 쪽에 `Spacer`, single에선
/// 있는 슬롯만 단독 렌더 (빈 슬롯이 유령 spacing 안 남김).
///
/// ```swift
/// AdaptiveFieldRow {
///     ProjectFieldView(...)
/// } right: {
///     ServicesFieldView(...)
/// }
///
/// // 오른쪽 슬롯 없는 케이스 (Service Account의 Environment 미노출 등)
/// AdaptiveFieldRow {
///     ExpireDateFieldView(...)
/// }
///
/// // 왼쪽 슬롯 없는 케이스 (dual에서 오른쪽 절반만 사용)
/// AdaptiveFieldRow(right: {
///     SomeFieldView(...)
/// })
/// ```
struct AdaptiveFieldRow<Left: View, Right: View>: View {

    @Environment(\.formLayoutMode) private var mode

    private let left: (() -> Left)?
    private let right: (() -> Right)?

    init(
        @ViewBuilder left: @escaping () -> Left,
        @ViewBuilder right: @escaping () -> Right
    ) {
        self.left = left
        self.right = right
    }

    @ViewBuilder
    var body: some View {
        switch mode {
        case .dual:
            HStack(alignment: .top, spacing: 16) {
                if let left {
                    left()
                } else {
                    Spacer(minLength: 0)
                }
                if let right {
                    right()
                } else {
                    Spacer(minLength: 0)
                }
            }
        case .single:
            if let left, let right {
                VStack(alignment: .leading, spacing: 16) {
                    left()
                    right()
                }
            } else if let left {
                left()
            } else if let right {
                right()
            }
        }
    }
}

extension AdaptiveFieldRow where Right == EmptyView {
    /// 오른쪽 슬롯이 비어있는 케이스용 편의 init.
    init(@ViewBuilder left: @escaping () -> Left) {
        self.left = left
        self.right = nil
    }
}

extension AdaptiveFieldRow where Left == EmptyView {
    /// 왼쪽 슬롯이 비어있는 케이스용 편의 init — 아직 소비처는 없으나 대칭성 유지.
    init(@ViewBuilder right: @escaping () -> Right) {
        self.left = nil
        self.right = right
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
