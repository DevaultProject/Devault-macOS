// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVTitleBar: View {

    // MARK: - Properties

    public let titleText: String
    public let searchText: Binding<String>
    public let searchPromptText: String
    public let onSortTapped: () -> Void

    // MARK: - Init

    public init(
        titleText: String,
        searchText: Binding<String>,
        searchPromptText: String = "Search",
        onSortTapped: @escaping () -> Void
    ) {
        self.titleText = titleText
        self.searchText = searchText
        self.searchPromptText = searchPromptText
        self.onSortTapped = onSortTapped
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleRow
            searchField
        }
        .frame(width: 280)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Subviews

extension DVTitleBar {

    private var titleRow: some View {
        HStack {
            Text(titleText)
                .dvFont(.headingXL)
                .foregroundStyle(Color.dv(.gray900))
            Spacer()
            sortButton
        }
    }

    private var sortButton: some View {
        Button(action: onSortTapped) {
            Image(systemName: "arrow.up.arrow.down")
                .dvFont(.bodyXL)
                .foregroundStyle(Color.dv(.gray600))
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.gray500))
            TextField(searchPromptText, text: searchText)
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.gray900))
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
