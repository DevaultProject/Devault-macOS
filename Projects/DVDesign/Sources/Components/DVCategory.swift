// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVCategory: View {

    // MARK: - Properties

    public let title: String
    public let count: Int
    public let isSelected: Bool
    public let action: () -> Void

    @State private var isHovered = false

    // MARK: - Init

    public init(
        title: String,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            contentLayer
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 108, height: 72)
        .background(isSelected ? Color.dv(.vaultGreen) : Color.dv(.gray100))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(borderOverlay)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Subviews

extension DVCategory {

    private var contentLayer: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                iconCircle
                Spacer()
                countLabel
            }
            Spacer()
            titleLabel
        }
        .padding(12)
    }

    private var iconCircle: some View {
        Circle()
            .fill(isSelected ? Color.dv(.white).opacity(0.25) : Color.dv(.gray300))
            .frame(width: 28, height: 28)
    }

    private var titleLabel: some View {
        Text(title)
            .dvFont(.bodyLG)
            .foregroundStyle(isSelected ? Color.dv(.white) : Color.dv(.gray800))
    }

    private var countLabel: some View {
        Text(count > 999 ? "999+" : "\(count)")
            .dvFont(.bodyMD)
            .foregroundStyle(isSelected ? Color.dv(.white).opacity(0.8) : Color.dv(.gray600))
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isHovered && !isSelected ? Color.dv(.gray300) : Color.clear, lineWidth: 1)
    }
}
