// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVButtonPreviewView: View {

    // MARK: - Properties

    @State private var tapCount = 0
    @State private var isStarted = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection("Interactive (탭 횟수: \(tapCount))") {
                    DVButton(titleText: "action check") { tapCount += 1 }
                }
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
            DVButton(titleText: isStarted ? "Done!" : "Start") { isStarted.toggle() }
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
    }

    private var buttonPair: some View {
        VStack(spacing: 8) {
            DVButton(titleText: "Cancel", style: .secondary) {}
            DVButton(titleText: "Create") {}
        }
    }
}
