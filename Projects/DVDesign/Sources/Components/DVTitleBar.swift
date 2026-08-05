// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVTitleBar: View {

    // MARK: - Properties

    public let titleText: String
    public let searchText: Binding<String>
    public let searchPromptText: String
    public let onSortTapped: (() -> Void)?

    // MARK: - Init

    /// - Parameter onSortTapped: 정렬 버튼 탭 핸들러. `nil`이면 정렬 버튼 자체를 그리지 않는다.
    public init(
        titleText: String,
        searchText: Binding<String>,
        searchPromptText: String = "Search",
        onSortTapped: (() -> Void)? = nil
    ) {
        self.titleText = titleText
        self.searchText = searchText
        self.searchPromptText = searchPromptText
        self.onSortTapped = onSortTapped
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            titleRow
            searchField
        }
        .frame(maxWidth: .infinity)
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
            if let onSortTapped {
                sortButton(action: onSortTapped)
            }
        }
        .padding(.vertical, 4)
    }

    private func sortButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "arrow.up.arrow.down")
                .dvFont(.bodyXL)
                .foregroundStyle(Color.dv(.gray800))
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
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
