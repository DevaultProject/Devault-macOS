// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// CreateSecret 화면 하단 고정 액션 바. Cancel + Save, 10pt 간격 고정 + 우측 정렬.
/// TCA store에 결합하지 않고 콜백/불리언만 받아 독립 Preview 가능.
struct FooterActionsView: View {

    let isSaveEnabled: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 10) {
                DVButton(titleText: "Cancel", style: .secondary, action: onCancel)
                SaveButtonView(isEnabled: isSaveEnabled, action: onSave)
            }
        }
        .padding(.top, 8)
    }
}

/// DVButton의 secondary 지오메트리를 재사용하되, enabled 시 vaultGreen 배경으로 강조하는 Save 전용 버튼.
/// 재사용 필요 시 DVDesign에 새 `DVButton.Style` variant로 승격 예정.
private struct SaveButtonView: View {

    let isEnabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text("Save")
                .dvFont(.bodyMD)
                .frame(width: 74, height: 24)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(SaveButtonStyle(isHovered: isHovered))
        .disabled(!isEnabled)
        .onHover { isHovered = $0 }
    }
}

private struct SaveButtonStyle: ButtonStyle {

    let isHovered: Bool

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var foregroundColor: Color {
        isEnabled ? Color.dv(.white) : Color.dv(.gray400)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        guard isEnabled else { return Color.dv(.gray100) }
        return (isPressed || isHovered) ? Color.dv(.vaultGreenDark) : Color.dv(.vaultGreen)
    }
}

// MARK: - Preview

#Preview("Disabled · Medium") {
    FooterActionsView(isSaveEnabled: false, onCancel: {}, onSave: {})
        .previewWidth(.medium)
}

#Preview("Enabled · Medium") {
    FooterActionsView(isSaveEnabled: true, onCancel: {}, onSave: {})
        .previewWidth(.medium)
}

#Preview("Enabled · Narrow") {
    FooterActionsView(isSaveEnabled: true, onCancel: {}, onSave: {})
        .previewWidth(.narrow)
}

#Preview("Enabled · Wide") {
    FooterActionsView(isSaveEnabled: true, onCancel: {}, onSave: {})
        .previewWidth(.wide)
}
