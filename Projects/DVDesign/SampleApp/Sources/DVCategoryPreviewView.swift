// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVCategoryPreviewView: View {
    @State private var selected = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection("Interactive") {
                    HStack(spacing: 8) {
                        DVCategory(title: "All",     count: 999, isSelected: selected == 0) { selected = 0 }
                        DVCategory(title: "Star",    count: 12,  isSelected: selected == 1) { selected = 1 }
                        DVCategory(title: "Expired", count: 5,   isSelected: selected == 2) { selected = 2 }
                        DVCategory(title: "Deleted", count: 3,   isSelected: selected == 3) { selected = 3 }
                    }
                }

                previewSection("Selected") {
                    DVCategory(title: "All", count: 999, isSelected: true) {}
                }

                previewSection("Unselected") {
                    DVCategory(title: "All", count: 999, isSelected: false) {}
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVCategory")
    }
}
