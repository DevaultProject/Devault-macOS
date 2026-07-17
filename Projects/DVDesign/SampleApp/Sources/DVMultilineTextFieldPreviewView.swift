// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVMultilineTextFieldPreviewView: View {
    @State private var emptyValue = ""
    @State private var envSet = """
    DATABASE_URL=postgres://user:pass@localhost:5432/mydb
    OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    SECRET_KEY=abc123
    """
    @State private var jsonValue = ""
    @State private var xsValue = ""
    @State private var smValue = ""
    @State private var mdValue = ""
    @State private var lgValue = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "상태") {
                    labeled("Empty — placeholder 오버레이") {
                        DVMultilineTextField(
                            "e.g DATABASE_URL=postgres://...",
                            text: $emptyValue,
                            size: .lg
                        )
                    }
                    labeled("Active — 여러 줄 입력값") {
                        DVMultilineTextField(
                            "e.g DATABASE_URL=...",
                            text: $envSet,
                            size: .lg
                        )
                    }
                }

                section(title: "사이즈 (DVComponentSize 전 케이스)") {
                    labeled("XS (180pt)") {
                        DVMultilineTextField("XS", text: $xsValue, size: .xs, height: 80)
                    }
                    labeled("SM (330pt)") {
                        DVMultilineTextField("SM", text: $smValue, size: .sm, height: 80)
                    }
                    labeled("MD (380pt)") {
                        DVMultilineTextField("MD", text: $mdValue, size: .md, height: 80)
                    }
                    labeled("LG (700pt) — 기본") {
                        DVMultilineTextField(
                            "e.g Service Account JSON",
                            text: $lgValue,
                            size: .lg
                        )
                    }
                }

                section(title: "min height 확장") {
                    labeled("minHeight 200 — 여유 공간이 필요할 때") {
                        DVMultilineTextField(
                            "긴 SSH private key 붙여넣기",
                            text: $jsonValue,
                            size: .lg,
                            height: 200
                        )
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVMultilineTextField")
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
