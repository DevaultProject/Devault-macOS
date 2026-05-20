// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVProjectContainerPreviewView: View {
    @State private var selected: String? = nil

    private let projects = [
        ("CheerLot", 8),
        ("DrinkiG", 8),
        ("LongLongNameExample", 8),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection("Interactive") {
                    VStack(spacing: 2) {
                        ForEach(projects, id: \.0) { name, count in
                            DVProjectContainer(
                                name: name,
                                count: count,
                                isSelected: selected == name
                            ) { selected = selected == name ? nil : name }
                        }
                    }
                    .frame(width: 220)
                }

                previewSection("Selected") {
                    DVProjectContainer(name: "DrinkiG", count: 8, isSelected: true) {}
                        .frame(width: 220)
                }

                previewSection("Unselected") {
                    DVProjectContainer(name: "DrinkiG", count: 8, isSelected: false) {}
                        .frame(width: 220)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVProjectContainer")
    }
}
