// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVCheckBox: View {

    // MARK: - Properties

    public let isChecked: Bool
    public let action: () -> Void

    @State private var isHovered = false

    // MARK: - Init

    public init(
        isChecked: Bool,
        action: @escaping () -> Void
    ) {
        self.isChecked = isChecked
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            checkboxShape
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Subviews

extension DVCheckBox {

    private var checkboxShape: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5.5)
                .fill(isChecked ? Color.dv(.vaultGreen) : Color.dv(.gray300))
                .frame(width: 16, height: 16)
                .overlay(borderOverlay)

            if isChecked {
                checkmarkIcon
            }
        }
    }

    private var checkmarkIcon: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.dv(.white))
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 5.5)
            .stroke(
                isHovered && !isChecked ? Color.dv(.gray400) : Color.clear,
                lineWidth: 1
            )
    }
}
