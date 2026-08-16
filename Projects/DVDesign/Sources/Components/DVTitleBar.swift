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
    /// 검색 필드의 포커스를 바깥에서 풀 수 있게 열어 둔다 — 한 번 커서가 들어가면 다른 곳을
    /// 눌러도 놓지 않는 경우가 있다. `nil`이면 시스템에 맡긴다.
    public let isSearchFocused: Binding<Bool>?

    @FocusState private var searchFieldFocused: Bool

    // MARK: - Init

    public init(
        titleText: String,
        searchText: Binding<String>,
        searchPromptText: String = "Search",
        isSearchFocused: Binding<Bool>? = nil,
        sortMenuContent: (() -> AnyView)? = nil
    ) {
        self.titleText = titleText
        self.searchText = searchText
        self.searchPromptText = searchPromptText
        self.isSearchFocused = isSearchFocused
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
                .focused($searchFieldFocused)
                // `@FocusState`는 뷰 안에서만 쓸 수 있어 두 방향을 각각 흘려보내야 한다.
                .onChange(of: searchFieldFocused) { _, focused in
                    isSearchFocused?.wrappedValue = focused
                }
                .onChange(of: isSearchFocused?.wrappedValue) { _, requested in
                    guard let requested, requested != searchFieldFocused else { return }
                    searchFieldFocused = requested
                }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
