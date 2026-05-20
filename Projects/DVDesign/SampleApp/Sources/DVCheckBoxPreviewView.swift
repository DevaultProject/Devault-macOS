// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVCheckBoxPreviewView: View {

    // MARK: - Properties

    @State private var isChecked = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection("Interactive") {
                    interactiveRow
                }
                previewSection("Checked") {
                    DVCheckBox(isChecked: true) {}
                }
                previewSection("Unchecked") {
                    DVCheckBox(isChecked: false) {}
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVCheckBox")
    }
}

// MARK: - Subviews

extension DVCheckBoxPreviewView {

    private var interactiveRow: some View {
        HStack(spacing: 12) {
            DVCheckBox(isChecked: isChecked) { isChecked.toggle() }
            Text(isChecked ? "Checked" : "Unchecked")
                .foregroundStyle(.secondary)
        }
    }
}
