// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVButton: View {

    // MARK: - Types

    public enum Style {
        case primary
        case secondary

        var cornerRadius: CGFloat {
            switch self {
            case .primary:   return 20
            case .secondary: return 6
            }
        }

        var height: CGFloat {
            switch self {
            case .primary:   return 40
            case .secondary: return 24
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .primary:   return 16
            case .secondary: return 16
            }
        }

        var width: CGFloat {
            switch self {
            case .primary:   return 242
            case .secondary: return 74
            }
        }

        var font: DVFont {
            switch self {
            case .primary:   return .bodyLG
            case .secondary: return .bodyMD
            }
        }
    }

    // MARK: - Properties

    public let titleText: String
    public let style: Style
    public let action: () -> Void

    @State private var isHovered = false

    // MARK: - Init

    public init(
        titleText: String,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.titleText = titleText
        self.style = style
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            labelView
        }
        .buttonStyle(DVButtonStyle(isHovered: isHovered, style: style))
        .onHover { isHovered = $0 }
    }
}

// MARK: - Subviews

extension DVButton {

    private var labelView: some View {
        Text(titleText)
            .dvFont(style.font)
            .frame(width: style.width, height: style.height)
            .padding(.horizontal, style.horizontalPadding)
    }
}

// MARK: - ButtonStyle

private struct DVButtonStyle: ButtonStyle {

    let isHovered: Bool
    let style: DVButton.Style

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color.dv(.white)
        case .secondary:
            return isEnabled ? Color.dv(.gray800) : Color.dv(.gray400)
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch style {
        case .primary:
            if !isEnabled { return Color.dv(.vaultGreenTint) }
            if isPressed || isHovered { return Color.dv(.vaultGreenDark) }
            return Color.dv(.vaultGreen)
        case .secondary:
            if !isEnabled { return Color.dv(.gray100) }
            if isPressed || isHovered { return Color.dv(.gray200) }
            return Color.dv(.gray100)
        }
    }
}
