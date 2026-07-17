// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVDropdownPreviewView: View {
    @State private var project: String? = nil
    @State private var env: String? = "Staging"
    @State private var xs: String? = nil
    @State private var md: String? = nil
    @State private var lg: String? = nil

    private let projects = ["CheerLot", "DrinkiG", "LongLongNameExample"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "기본") {
                    labeled("Placeholder — 아직 선택 안 함") {
                        DVDropdown(project ?? "Select Project", size: .sm) {
                            ForEach(projects, id: \.self) { name in
                                Button(name) { project = name }
                            }
                            Divider()
                            Button {
                                // add new project
                            } label: {
                                Label("Add New Project", systemImage: "plus")
                            }
                        }
                    }
                    labeled("Selected — 값 있음") {
                        DVDropdown(env ?? "Select Env", size: .sm) {
                            Button("Dev")     { env = "Dev" }
                            Button("Staging") { env = "Staging" }
                            Button("Prod")    { env = "Prod" }
                        }
                    }
                }

                section(title: "사이즈 (DVComponentSize 전 케이스)") {
                    labeled("XS (180pt)") {
                        DVDropdown(xs ?? "XS", size: .xs) {
                            Button("Option 1") { xs = "Option 1" }
                            Button("Option 2") { xs = "Option 2" }
                        }
                    }
                    labeled("SM (330pt)") {
                        DVDropdown(project ?? "Select Project", size: .sm) {
                            ForEach(projects, id: \.self) { name in
                                Button(name) { project = name }
                            }
                        }
                    }
                    labeled("MD (380pt)") {
                        DVDropdown(md ?? "Select Region", size: .md) {
                            Button("us-east-1") { md = "us-east-1" }
                            Button("ap-northeast-2") { md = "ap-northeast-2" }
                        }
                    }
                    labeled("LG (700pt)") {
                        DVDropdown(lg ?? "Select Very Long Value", size: .lg) {
                            Button("A") { lg = "Option A" }
                            Button("B") { lg = "Option B" }
                        }
                    }
                }

                section(title: "긴 텍스트 truncation") {
                    labeled("SM 사이즈 + 긴 프로젝트명 → 뒤가 잘림 (tail truncation)") {
                        DVDropdown("SuperLongProjectNameThatExceedsWidth", size: .sm) {
                            Button("A") {}
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVDropdown")
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
