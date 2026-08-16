// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVTitleBar: View {

    // MARK: - Properties

    public let titleText: String
    public let searchText: Binding<String>
    public let searchPromptText: String
    /// 정렬 버튼을 누르면 펼쳐질 메뉴 내용. `nil`이면 정렬 버튼 자체를 그리지 않는다.
    /// 클로저가 반환하는 뷰가 시스템 `Menu` 안에 들어가므로, 바깥 클릭·ESC·포커스 상실 처리는 시스템이 담당한다.
    public let sortMenuContent: (() -> AnyView)?

    // MARK: - Init

    public init(
        titleText: String,
        searchText: Binding<String>,
        searchPromptText: String = "Search",
        sortMenuContent: (() -> AnyView)? = nil
    ) {
        self.titleText = titleText
        self.searchText = searchText
        self.searchPromptText = searchPromptText
        self.sortMenuContent = sortMenuContent
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
            if let sortMenuContent {
                sortMenu(content: sortMenuContent)
            }
        }
        .padding(.vertical, 4)
    }

    private func sortMenu(content: () -> AnyView) -> some View {
        Menu {
            content()
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .dvFont(.bodyXL)
                .foregroundStyle(Color.dv(.gray800))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
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
