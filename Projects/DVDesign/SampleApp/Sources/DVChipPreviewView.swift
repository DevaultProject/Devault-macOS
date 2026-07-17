// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVChipPreviewView: View {
    @State private var chips: [String] = ["GitHub", "NameNameName", "OpenAI"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "기본") {
                    labeled("단일 chip") {
                        DVChip("GitHub")
                    }
                    labeled("여러 chip (수평 배치)") {
                        HStack(spacing: 10) {
                            DVChip("GitHub")
                            DVChip("OpenAI")
                            DVChip("Anthropic")
                            DVChip("LongLongName")
                        }
                    }
                }

                section(title: "인터랙션 — 클릭 시 제거") {
                    labeled("각 chip 클릭 시 목록에서 제거됨") {
                        HStack(spacing: 10) {
                            ForEach(chips, id: \.self) { chip in
                                DVChip(chip) {
                                    chips.removeAll { $0 == chip }
                                }
                            }
                        }
                    }
                    Button("초기화") {
                        chips = ["GitHub", "NameNameName", "OpenAI"]
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVChip")
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
