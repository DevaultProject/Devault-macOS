// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVChipsFieldPreviewView: View {
    @State private var empty: [String] = []
    @State private var emptyInput = ""

    @State private var few: [String] = ["GitHub"]
    @State private var fewInput = ""

    @State private var many: [String] = [
        "GitHub", "OpenAI", "Anthropic", "AWS", "Slack", "Notion", "Linear",
        "Stripe", "Vercel", "Supabase", "LongLongLongService"
    ]
    @State private var manyInput = ""

    @State private var detected: [String] = []
    @State private var detectedInput = ""
    @State private var lastEvent = "이벤트 없음"

    @State private var xs: [String] = ["A", "B"]
    @State private var sm: [String] = ["GitHub", "OpenAI"]
    @State private var md: [String] = ["Stripe", "Vercel", "Supabase"]
    @State private var lg: [String] = ["GitHub", "OpenAI", "Anthropic", "AWS", "Slack", "Notion", "Linear", "Stripe"]
    @State private var xsInput = ""
    @State private var smInput = ""
    @State private var mdInput = ""
    @State private var lgInput = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "기본") {
                    labeled("Empty — chip 없음") {
                        DVChipsField("e.g GitHub", chips: empty, input: $emptyInput, size: .sm)
                    }
                    labeled("Chip 1개") {
                        DVChipsField("추가 입력", chips: few, input: $fewInput, size: .sm)
                    }
                    labeled("여러 개 — 세로 wrap 확인") {
                        DVChipsField("추가 입력", chips: many, input: $manyInput, size: .sm)
                    }
                }

                section(title: "인터랙션") {
                    labeled("Chip 클릭 → 텍스트 입력창에 세팅 + 원본은 시각적으로만 숨김. 다른 chip 클릭 시 이전 것 복귀") {
                        DVChipsField(
                            "chip 클릭해보기",
                            chips: ["GitHub", "OpenAI", "Anthropic"],
                            input: $detectedInput,
                            size: .sm,
                            onTap: { chip in lastEvent = "tap — \(chip)" }
                        )
                    }
                    Text("마지막 이벤트: \(lastEvent)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                section(title: "사이즈 (DVComponentSize 전 케이스)") {
                    labeled("XS (180pt)") {
                        DVChipsField("XS", chips: xs, input: $xsInput, size: .xs)
                    }
                    labeled("SM (330pt)") {
                        DVChipsField("SM", chips: sm, input: $smInput, size: .sm)
                    }
                    labeled("MD (380pt)") {
                        DVChipsField("MD", chips: md, input: $mdInput, size: .md)
                    }
                    labeled("LG (700pt)") {
                        DVChipsField("LG", chips: lg, input: $lgInput, size: .lg)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVChipsField")
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
