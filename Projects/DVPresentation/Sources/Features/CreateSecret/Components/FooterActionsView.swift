// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// CreateSecret 화면 하단 고정 액션 바. Cancel + Create, 10pt 간격 고정 + 우측 정렬.
/// TCA store에 결합하지 않고 콜백/불리언만 받아 독립 Preview 가능.
struct FooterActionsView: View {

    let isSaveEnabled: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        actions
            .padding(.top, 8)
    }
}

// MARK: - Subviews

extension FooterActionsView {

    private var actions: some View {
        HStack {
            Spacer()
            HStack(spacing: 10) {
                DVButton(titleText: .module("Cancel"), style: .secondary, action: onCancel)
                DVButton(titleText: .module("Create"), style: .secondaryProminent, action: onSave)
                    .disabled(!isSaveEnabled)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG

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

#endif
