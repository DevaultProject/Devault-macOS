// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVButton: View {

    // MARK: - Types

    public enum Style {
        case primary
        case primarySmall
        /// 회색 배경 secondary 버튼 (Cancel 등).
        case secondary
        /// secondary와 동일한 지오메트리에 vaultGreen 강조 배경 (Create/Save 등 확정 액션).
        case secondaryProminent

        var cornerRadius: CGFloat {
            switch self {
            case .primary, .primarySmall:            return 20
            case .secondary, .secondaryProminent:    return 6
            }
        }

        var minHeight: CGFloat {
            switch self {
            case .primary, .primarySmall:            return 40
            case .secondary, .secondaryProminent:    return 24
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .primary, .primarySmall,
                 .secondary, .secondaryProminent:    return 16
            }
        }

        /// 컨텐츠가 짧을 때 floor로 유지되는 최소 폭. text가 길면 자연 확장.
        var minWidth: CGFloat {
            switch self {
            case .primary:                           return 242
            case .primarySmall:                      return 134
            case .secondary, .secondaryProminent:    return 74
            }
        }

        var font: DVFont {
            switch self {
            case .primary, .primarySmall:            return .bodyLG
            case .secondary, .secondaryProminent:    return .bodyMD
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
            .padding(.horizontal, style.horizontalPadding)
            .frame(minWidth: style.minWidth, minHeight: style.minHeight)
            .contentShape(Rectangle())
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
        case .primary, .primarySmall:
            return Color.dv(.white)
        case .secondary:
            return isEnabled ? Color.dv(.gray800) : Color.dv(.gray400)
        case .secondaryProminent:
            return isEnabled ? Color.dv(.white) : Color.dv(.gray400)
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch style {
        case .primary, .primarySmall:
            if !isEnabled { return Color.dv(.vaultGreenTint) }
            if isPressed || isHovered { return Color.dv(.vaultGreenDark) }
            return Color.dv(.vaultGreen)
        case .secondary:
            if !isEnabled { return Color.dv(.gray100) }
            if isPressed || isHovered { return Color.dv(.gray200) }
            return Color.dv(.gray100)
        case .secondaryProminent:
            if !isEnabled { return Color.dv(.gray100) }
            if isPressed || isHovered { return Color.dv(.vaultGreenDark) }
            return Color.dv(.vaultGreen)
        }
    }
}
