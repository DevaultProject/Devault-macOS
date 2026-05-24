// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct TextFieldPreviewView: View {
    @State private var emptyValue = ""
    @State private var filledValue = "DeVault"
    @State private var xs = ""
    @State private var sm = ""
    @State private var md = "DeVault"
    @State private var lg = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "상태") {
                    labeled("Placeholder (text 비어 있음)") {
                        DVTextField("e.g DeVault", text: $emptyValue, size: .md)
                    }
                    labeled("Active (text 채워짐)") {
                        DVTextField("e.g DeVault", text: $filledValue, size: .md)
                    }
                    labeled("Focus는 클릭/Tab 시 cursor가 vaultGreen으로 표시") {
                        DVTextField("focus 진입해보세요", text: $emptyValue, size: .md)
                    }
                }

                section(title: "사이즈") {
                    labeled("XS (180pt)") { DVTextField("XS", text: $xs, size: .xs) }
                    labeled("SM (330pt)") { DVTextField("SM", text: $sm, size: .sm) }
                    labeled("MD (380pt)") { DVTextField("MD", text: $md, size: .md) }
                    labeled("LG (700pt)") { DVTextField("LG", text: $lg, size: .lg) }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("TextField")
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.title2).fontWeight(.bold)
            content()
        }
    }

    @ViewBuilder
    private func labeled<Content: View>(
        _ caption: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }
}
