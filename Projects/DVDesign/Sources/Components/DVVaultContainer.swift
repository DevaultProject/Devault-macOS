// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVVaultContainer: View {

    // MARK: - Types

    public enum TrailingIcon {
        case expiringSoon
        case expired
    }

    // MARK: - Properties

    public let name: String
    public let date: String
    public let isSelected: Bool
    public let trailingIcon: TrailingIcon?
    public let action: () -> Void

    @State private var isHovered = false

    // MARK: - Init

    public init(
        name: String,
        date: String,
        isSelected: Bool,
        trailingIcon: TrailingIcon? = nil,
        action: @escaping () -> Void
    ) {
        self.name = name
        self.date = date
        self.isSelected = isSelected
        self.trailingIcon = trailingIcon
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            rowContent
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 280)
        .background(isSelected ? Color.dv(.vaultGreen) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(borderOverlay)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Subviews

extension DVVaultContainer {

    private var rowContent: some View {
        HStack(spacing: 12) {
            avatarCircle
            textStack
            Spacer()
            trailingIconView
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var avatarCircle: some View {
        Circle()
            .fill(isSelected ? Color.dv(.white).opacity(0.25) : Color.dv(.gray300))
            .frame(width: 44, height: 44)
    }

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .dvFont(.bodyLG)
                .foregroundStyle(isSelected ? Color.dv(.white) : Color.dv(.gray900))
                .lineLimit(1)
            Text(date)
                .dvFont(.captionMDRegular)
                .foregroundStyle(isSelected ? Color.dv(.white).opacity(0.7) : Color.dv(.gray500))
        }
    }

    @ViewBuilder
    private var trailingIconView: some View {
        if let trailingIcon {
            Image(systemName: trailingIcon.iconName)
                .foregroundStyle(isSelected ? Color.dv(.white) : trailingIcon.iconColor)
        }
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(isHovered && !isSelected ? Color.dv(.gray300) : Color.clear, lineWidth: 1)
    }
}

// MARK: - TrailingIcon Appearance

extension DVVaultContainer.TrailingIcon {

    fileprivate var iconName: String {
        switch self {
        case .expiringSoon: return "clock"
        case .expired:      return "exclamationmark.circle"
        }
    }

    fileprivate var iconColor: Color {
        switch self {
        case .expiringSoon: return Color.dv(.warning)
        case .expired:      return Color.dv(.danger)
        }
    }
}
