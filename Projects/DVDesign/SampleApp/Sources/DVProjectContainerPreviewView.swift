// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVProjectContainerPreviewView: View {
    @State private var selectedIndex: Int? = nil

    private let projects = [
        ("CheerLot", 8),
        ("DrinkiG", 8),
        ("LongLongNameExample", 8),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection("Interactive (List)") {
                    List(selection: $selectedIndex) {
                        ForEach(projects.indices, id: \.self) { index in
                            DVProjectContainer(
                                name: projects[index].0,
                                count: projects[index].1
                            )
                            .tag(index)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .contextMenu {
                                Button("이름 변경") {}
                                Divider()
                                Button("삭제", role: .destructive) {}
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .tint(Color.dv(.vaultGreen))
                    .frame(width: 228, height: 100)
                }

                previewSection("Default") {
                    DVProjectContainer(name: "DrinkiG", count: 8)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVProjectContainer")
    }
}
