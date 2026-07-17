// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVLabeledFieldPreviewView: View {
    @State private var name = ""
    @State private var value = "ghp_1234567890abcdef"
    @State private var memo = ""
    @State private var project: String? = nil
    @State private var envContent = ""
    @State private var xs = ""
    @State private var sm = ""
    @State private var md = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "상태") {
                    labeled("힌트 없음") {
                        DVLabeledField("Memo", size: .lg) {
                            DVTextField("optional", text: $memo, size: .lg)
                        }
                    }
                    labeled("필수 (*)") {
                        DVLabeledField("Name", isRequired: true, size: .lg) {
                            DVTextField("e.g DeVault", text: $name, size: .lg)
                        }
                    }
                    labeled("Detected 힌트 (초록)") {
                        DVLabeledField(
                            "Value",
                            isRequired: true,
                            trailingHint: .detected("Auto-detected: GitHub"),
                            size: .lg
                        ) {
                            DVTextField("secret value", text: $value, size: .lg)
                        }
                    }
                    labeled("Warning 힌트 (빨강)") {
                        DVLabeledField(
                            "Name",
                            isRequired: true,
                            trailingHint: .warning("필수 항목입니다"),
                            size: .lg
                        ) {
                            DVTextField("e.g DeVault", text: $name, size: .lg)
                        }
                    }
                }

                section(title: "다양한 input 조합") {
                    labeled("DVDropdown 감싸기") {
                        DVLabeledField("Project", size: .sm) {
                            DVDropdown(project ?? "Select Project", size: .sm) {
                                Button("CheerLot")  { project = "CheerLot" }
                                Button("DrinkiG")   { project = "DrinkiG" }
                            }
                        }
                    }
                    labeled("DVMultilineTextField 감싸기") {
                        DVLabeledField(
                            "Env Content",
                            isRequired: true,
                            trailingHint: .detected("Auto-detected: .env format"),
                            size: .lg
                        ) {
                            DVMultilineTextField(
                                "e.g DATABASE_URL=postgres://...",
                                text: $envContent,
                                size: .lg,
                                height: 120
                            )
                        }
                    }
                }

                section(title: "사이즈 (DVComponentSize 전 케이스)") {
                    DVLabeledField("XS", isRequired: true, size: .xs) {
                        DVTextField("XS", text: $xs, size: .xs)
                    }
                    DVLabeledField("SM", isRequired: true, size: .sm) {
                        DVTextField("SM", text: $sm, size: .sm)
                    }
                    DVLabeledField("MD", isRequired: true, trailingHint: .detected("hint"), size: .md) {
                        DVTextField("MD", text: $md, size: .md)
                    }
                    DVLabeledField(
                        "LG",
                        isRequired: true,
                        trailingHint: .detected("Auto-detected: GitHub"),
                        size: .lg
                    ) {
                        DVTextField("LG", text: $value, size: .lg)
                    }
                }

                section(title: "긴 hint truncation") {
                    labeled("SM 사이즈 + 긴 warning → tail truncation") {
                        DVLabeledField(
                            "Value",
                            isRequired: true,
                            trailingHint: .warning("This is a really really really long warning message that should truncate"),
                            size: .sm
                        ) {
                            DVTextField("SM", text: $sm, size: .sm)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVLabeledField")
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
