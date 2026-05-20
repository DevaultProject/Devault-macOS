// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVProjectContainer: View {

    // MARK: - Properties

    public let name: String
    public let count: Int
    public let isSelected: Bool
    public let action: () -> Void

    @State private var isHovered = false

    // MARK: - Init

    public init(
        name: String,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.name = name
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            rowContent
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 228, height: 28)
        .background(isSelected ? Color.dv(.vaultGreen) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(borderOverlay)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Subviews

extension DVProjectContainer {

    private var rowContent: some View {
        HStack(spacing: 8) {
            projectIcon
            nameLabel
            Spacer()
            countLabel
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var projectIcon: some View {
        Image(systemName: "tray")
            .dvFont(.captionLG)
            .foregroundStyle(isSelected ? Color.dv(.white) : Color.dv(.gray700))
    }

    private var nameLabel: some View {
        Text(name)
            .dvFont(.bodyMD)
            .foregroundStyle(isSelected ? Color.dv(.white) : Color.dv(.gray900))
            .lineLimit(1)
    }

    private var countLabel: some View {
        Text("\(count)")
            .dvFont(.bodyMD)
            .foregroundStyle(isSelected ? Color.dv(.white).opacity(0.8) : Color.dv(.gray500))
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(isHovered && !isSelected ? Color.dv(.gray300) : Color.clear, lineWidth: 1)
    }
}
