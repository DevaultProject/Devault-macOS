// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct RadioButtonPreviewView: View {
    @State private var singleSelected: Bool = false
    @State private var xsSelection: Environment = .dev
    @State private var smSelection: Environment = .staging
    @State private var mdSelection: Environment = .prod

    private enum Environment: Hashable {
        case dev, staging, prod
    }

    private var items: [DVRadioButtonGroup<Environment>.Item] {
        [
            .init(.dev, title: "Dev"),
            .init(.staging, title: "Staging"),
            .init(.prod, title: "Prod"),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "DVRadioButton") {
                    HStack(spacing: 40) {
                        labeled("Default") {
                            DVRadioButton("Dev", isSelected: false, action: {})
                        }
                        labeled("Selected") {
                            DVRadioButton("Dev", isSelected: true, action: {})
                        }
                        labeled("Interactive") {
                            DVRadioButton(
                                "Tap me",
                                isSelected: singleSelected
                            ) {
                                singleSelected.toggle()
                            }
                        }
                    }
                }

                section(title: "DVRadioButtonGroup") {
                    VStack(alignment: .leading, spacing: 20) {
                        labeled("XS (spacing 8)") {
                            DVRadioButtonGroup(
                                items: items,
                                selection: $xsSelection,
                                size: .xs
                            )
                        }
                        labeled("SM (spacing 20)") {
                            DVRadioButtonGroup(
                                items: items,
                                selection: $smSelection,
                                size: .sm
                            )
                        }
                        labeled("MD (spacing 28)") {
                            DVRadioButtonGroup(
                                items: items,
                                selection: $mdSelection,
                                size: .md
                            )
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("RadioButton")
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            content()
        }
    }

    @ViewBuilder
    private func labeled<Content: View>(
        _ caption: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }
}
