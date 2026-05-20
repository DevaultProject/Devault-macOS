// Copyright © 2026 Devault. All rights reserved

import SwiftUI

@ViewBuilder
func previewSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
        content()
    }
}
