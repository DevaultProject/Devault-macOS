// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVCategory: View {

    // MARK: - Properties

    public let title: String
    public let count: Int
    public let systemImage: String
    public let isSelected: Bool
    public let action: () -> Void

    @State private var isHovered = false

    // MARK: - Init

    public init(
        title: String,
        count: Int,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.count = count
        self.systemImage = systemImage
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
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.easeOut(duration: 0.12), value: isSelected)
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
            .foregroundStyle(isSelected ? Color.dv(.white) : Color.dv(.gray800))
            .frame(width: 24, height: 24)
    }

    private var titleLabel: some View {
        Text(title)
            .dvFont(.bodyLG)
            .foregroundStyle(isSelected ? Color.dv(.white) : Color.dv(.gray900))
    }

    private var countLabel: some View {
        Text(count > 999 ? "999+" : "\(count)")
            .dvFont(.bodyMD)
            .foregroundStyle(isSelected ? Color.dv(.white) : Color.dv(.gray600))
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
        if isPressed  { return Color.dv(.gray300) }
        if isHovered  { return Color.dv(.gray200) }
        return Color.dv(.gray200)
    }
}
