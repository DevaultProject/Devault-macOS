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
                        DVCategory(title: "All",     count: 999, systemImage: "tray",       isSelected: selected == 0) { selected = 0 }
                        DVCategory(title: "Star",    count: 12,  systemImage: "star.fill",  isSelected: selected == 1) { selected = 1 }
                        DVCategory(title: "Expired", count: 5,   systemImage: "clock",      isSelected: selected == 2) { selected = 2 }
                        DVCategory(title: "Deleted", count: 3,   systemImage: "trash",      isSelected: selected == 3) { selected = 3 }
                    }
                }

                previewSection("Selected") {
                    DVCategory(title: "All", count: 999, systemImage: "tray", isSelected: true) {}
                        .frame(width: 108)
                }

                previewSection("Unselected") {
                    DVCategory(title: "All", count: 999, systemImage: "tray", isSelected: false) {}
                        .frame(width: 108)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVCategory")
    }
}
