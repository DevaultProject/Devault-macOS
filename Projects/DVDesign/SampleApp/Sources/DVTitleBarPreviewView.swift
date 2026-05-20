// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVTitleBarPreviewView: View {

    // MARK: - Properties

    @State private var searchText = ""

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection("Interactive") {
                    DVTitleBar(
                        titleText: "All",
                        searchText: $searchText,
                        onSortTapped: {}
                    )
                    .frame(width: 280)
                    .background(Color.white)
                }
                previewSection("Expired") {
                    DVTitleBar(
                        titleText: "Expired",
                        searchText: .constant(""),
                        onSortTapped: {}
                    )
                    .frame(width: 280)
                    .background(Color.white)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVTitleBar")
    }
}
