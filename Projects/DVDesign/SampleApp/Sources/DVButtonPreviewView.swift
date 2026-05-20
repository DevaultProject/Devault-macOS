// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVButtonPreviewView: View {

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection("Primary") {
                    primaryStates
                }
                previewSection("Secondary") {
                    secondaryStates
                }
                previewSection("Button Pair") {
                    buttonPair
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVButton")
    }
}

// MARK: - Subviews

extension DVButtonPreviewView {

    private var primaryStates: some View {
        VStack(spacing: 8) {
            DVButton(titleText: "Start") {}
            DVButton(titleText: "Start") {}
                .disabled(true)
        }
        .frame(width: 242)
    }

    private var secondaryStates: some View {
        VStack(spacing: 8) {
            DVButton(titleText: "Cancel", style: .secondary) {}
            DVButton(titleText: "Cancel", style: .secondary) {}
                .disabled(true)
        }
        .frame(width: 74)
    }

    private var buttonPair: some View {
        VStack(spacing: 8) {
            DVButton(titleText: "Cancel", style: .secondary) {}
            DVButton(titleText: "Create") {}
        }
    }
}
