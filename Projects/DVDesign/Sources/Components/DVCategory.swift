// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVCategory: View {

    // MARK: - Properties

    public let title: String
    /// nil이면 개수 라벨을 그리지 않는다 — 아직 집계 전이거나 집계에 실패한 상태.
    /// 0으로 대체하면 "시크릿 없음"으로 읽히므로 자리를 비워 두는 쪽을 택한다.
    public let count: Int?
    public let systemImage: String
    public let iconColor: Color
    public let isSelected: Bool
    public let action: () -> Void

    @State private var isHovered = false

    // MARK: - Init

    public init(
        title: String,
        count: Int?,
        systemImage: String,
        iconColor: Color = Color.dv(.gray800),
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.count = count
        self.systemImage = systemImage
        self.iconColor = iconColor
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            contentLayer
                .contentShape(Rectangle())
        }
        .buttonStyle(DVCategoryButtonStyle(isHovered: isHovered, isSelected: isSelected))
        .animation(MotionMetrics.hover, value: isHovered)
        .animation(MotionMetrics.hover, value: isSelected)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Subviews

extension DVCategory {

    private var contentLayer: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                iconView
                Spacer()
                countLabel
            }
            Spacer()
            titleLabel
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 72)
    }

    private var iconView: some View {
        Image(systemName: systemImage)
            .dvFont(.headingLG)
            .foregroundStyle(isSelected ? Color.dv(.white) : iconColor)
            .frame(width: 24, height: 24)
    }

    private var titleLabel: some View {
        Text(title)
            .dvFont(.bodyLG)
            .foregroundStyle(isSelected ? Color.dv(.white) : Color.dv(.gray900))
    }

    @ViewBuilder
    private var countLabel: some View {
        if let count {
            Text(count > 999 ? "999+" : "\(count)")
                .dvFont(.bodyMD)
                .foregroundStyle(isSelected ? Color.dv(.white) : Color.dv(.gray600))
        }
    }
}

// MARK: - ButtonStyle

private struct DVCategoryButtonStyle: ButtonStyle {

    let isHovered: Bool
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isSelected { return Color.dv(.vaultGreen) }
        if isPressed  { return Color.dv(.gray400) }
        if isHovered  { return Color.dv(.gray300) }
        return Color.dv(.gray200)
    }
}
