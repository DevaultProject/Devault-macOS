// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVCore
import DVDesign
import DVDomain

// MARK: - SecretListView

struct SecretListView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<SecretListFeature>
  @State private var isSortMenuPresented = false

  // MARK: - Body

  var body: some View {
    content
      .task { store.send(.task) }
      .sheet(
        item: $store.scope(state: \.destination?.addToProject, action: \.destination.addToProject)
      ) { addToProjectStore in
        AddToProjectView(store: addToProjectStore)
      }
  }
}

// MARK: - Subviews

extension SecretListView {

  private var content: some View {
    ZStack(alignment: .topTrailing) {
      VStack(alignment: .leading, spacing: 12) {
        DVTitleBar(
          titleText: titleText,
          searchText: searchTextBinding,
          onSortTapped: showsSort ? { isSortMenuPresented.toggle() } : nil
        )
        .padding(.horizontal, 12)

        list
      }

      if isSortMenuPresented {
        Color.clear
          .contentShape(Rectangle())
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .onTapGesture { isSortMenuPresented = false }

        sortMenu
          .background(.regularMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .shadow(color: Color(nsColor: .shadowColor).opacity(0.15), radius: 16, y: 6)
          .padding(.top, 56)
          .padding(.trailing, 24)
      }
    }
  }

  private var list: some View {
    List(selection: selectedSecretIDBinding) {
      ForEach(secrets) { secret in
        DVVaultContainer(
          name: secret.name,
          date: SecretDateFormatter.string(from: secret.updatedAt),
          isSelected: secret.id == store.selectedSecretID
        )
        .tag(secret.id)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .contextMenu {
          contextMenuItems(for: secret)
        }
      }
    }
    .listStyle(.sidebar)
    .scrollContentBackground(.hidden)
    .tint(Color.dv(.vaultGreen))
  }

  /// All/Star/Expired는 "프로젝트에 추가/삭제", Deleted는 "복구/영구 삭제"를 보여준다.
  @ViewBuilder
  private func contextMenuItems(for secret: Secret) -> some View {
    switch store.collection {
    case .deleted:
      Button("Recover") {
        store.send(.didTapRecover(id: secret.id))
      }
      Button("Delete Forever", role: .destructive) {
        store.send(.didTapDeleteForever(id: secret.id))
      }

    case .all, .liked, .expired, .project:
      Button("Add to Project") {
        store.send(.didTapAddToProject(id: secret.id))
      }
      Button("Delete", role: .destructive) {
        store.send(.didTapDelete(id: secret.id))
      }
    }
  }

  private var sortMenu: some View {
    VStack(alignment: .leading, spacing: 2) {
      sortMenuRow(.recentlyAdded, title: "Recently Added")
      sortMenuRow(.oldestFirst, title: "Oldest First")
      sortMenuRow(.expiringSoon, title: "Expiring Soon")

      Divider()
        .padding(.vertical, 4)

      sortMenuRow(.nameAscending, title: "Name (A to Z)")
      sortMenuRow(.nameDescending, title: "Name (Z to A)")
    }
    .padding(6)
    .frame(width: 220)
  }

  private func sortMenuRow(_ value: SecretQuery.Sort, title: String) -> some View {
    SortMenuRow(title: title, isSelected: store.sort == value) {
      store.send(.didSelectSort(value))
      isSortMenuPresented = false
    }
  }

  private var secrets: IdentifiedArrayOf<Secret> {
    if case let .loaded(secrets) = store.secretsState {
      return secrets
    }
    return []
  }

  private var titleText: String {
    switch store.collection {
    case .all: return "All"
    case .liked: return "Star"
    case .expired: return "Expired"
    case .deleted: return "Deleted"
    case .project: return "Project"
    }
  }

  /// Expired/Deleted는 정렬이 필요 없는 화면이라 정렬 UI 자체를 숨긴다.
  private var showsSort: Bool {
    switch store.collection {
    case .all, .liked:
      return true
    case .expired, .deleted, .project:
      return false
    }
  }

  private var selectedSecretIDBinding: Binding<Secret.ID?> {
    Binding(
      get: { store.selectedSecretID },
      set: { store.send(.didSelectSecret(id: $0)) }
    )
  }

  private var searchTextBinding: Binding<String> {
    Binding(
      get: { store.searchText },
      set: { store.send(.didChangeSearchText($0)) }
    )
  }
}

// MARK: - SortMenuRow

/// 체크마크 + 호버 하이라이트를 갖는 네이티브 메뉴 스타일 행. 이 화면 전용 — 재사용 필요해지면 DVDesign으로 승격.
private struct SortMenuRow: View {

  let title: String
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Image(systemName: "checkmark")
          .dvFont(.bodyMD)
          .opacity(isSelected ? 1 : 0)
        Text(title)
          .dvFont(.bodyMD)
        Spacer(minLength: 8)
      }
      .foregroundStyle(isHovered ? Color(nsColor: .alternateSelectedControlTextColor) : Color.dv(.gray900))
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: 8)
          .fill(isHovered ? Color(nsColor: .selectedContentBackgroundColor) : Color.clear)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
  }
}

// MARK: - Preview

#Preview("All - 정렬 있음") {
  SecretListView(
    store: Store(initialState: SecretListFeature.State(collection: .all)) {
      SecretListFeature()
    } withDependencies: {
      $0.secretClient = .previewValue
    }
  )
  .frame(width: 300, height: 500)
}

#Preview("Expired - 정렬 없음") {
  SecretListView(
    store: Store(initialState: SecretListFeature.State(collection: .expired(referenceDate: .now))) {
      SecretListFeature()
    } withDependencies: {
      $0.secretClient = .previewValue
    }
  )
  .frame(width: 300, height: 500)
}

#Preview("Deleted - 정렬 없음, 우클릭: Recover/Delete Forever") {
  SecretListView(
    store: Store(initialState: SecretListFeature.State(collection: .deleted)) {
      SecretListFeature()
    } withDependencies: {
      $0.secretClient = .previewValue
    }
  )
  .frame(width: 300, height: 500)
}
