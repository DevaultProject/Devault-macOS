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

  // MARK: - Body

  var body: some View {
    content
      .task(id: store.collection) { store.send(.task) }
      .sheet(
        item: $store.scope(state: \.destination?.addToProject, action: \.destination.addToProject)
      ) { addToProjectStore in
        AddToProjectView(store: addToProjectStore)
      }
      .alert($store.scope(state: \.alert, action: \.alert))
  }
}

// MARK: - Subviews

extension SecretListView {

  private var content: some View {
    VStack(alignment: .leading, spacing: 12) {
      DVTitleBar(
        titleText: titleText,
        searchText: searchTextBinding,
        sortMenuContent: showsSort ? { AnyView(sortMenuContent) } : nil
      )
      .padding(.horizontal, 12)

      switch store.secretsState {
      case .failed:
        errorView
      case .loaded(let secrets) where secrets.isEmpty:
        emptyView
      default:
        list
      }
    }
  }

  private var list: some View {
    List(selection: selectedSecretIDBinding) {
      if case let .expired(referenceDate) = store.collection {
        expirySections(referenceDate: referenceDate)
      } else {
        ForEach(secrets) { secret in
          row(for: secret)
        }
      }
    }
    .listStyle(.sidebar)
    .scrollContentBackground(.hidden)
    .tint(Color(nsColor: .controlAccentColor).opacity(0.6))
  }

  /// "이미 지남"과 "N일 이내 예정"을 섹션으로 나눠 보여준다. 쿼리가 이미 `expiringSoon` 순으로 정렬해 와서
  /// 버킷 안에서 다시 정렬할 필요는 없다.
  @ViewBuilder
  private func expirySections(referenceDate: Date) -> some View {
    ForEach(ExpiryBucket.allCases) { bucket in
      let bucketSecrets = secrets.filter { bucket.contains($0.expiresAt, referenceDate: referenceDate) }
      if !bucketSecrets.isEmpty {
        Section {
          ForEach(bucketSecrets) { secret in
            row(for: secret)
          }
        } header: {
          Text(bucket.title)
            .dvFont(.captionMDSemibold)
            .foregroundStyle(Color(nsColor: .controlAccentColor))
        }
      }
    }
  }

  private func row(for secret: Secret) -> some View {
    DVVaultContainer(
      name: secret.name,
      date: SecretDateFormatter.string(from: secret.updatedAt),
      service: secret.service,
      typeIcon: secret.secretType.icon,
      trailingIcon: trailingIcon(for: secret),
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

  /// All/Star/Expired/Deleted 어디서든 만료 상태를 알려준다.
  /// 임계값은 `SecretExpiryStatus`가 소유한다 — 조회 화면 Expire Date 필드와 같은 정책을 써야 한다.
  private func trailingIcon(for secret: Secret) -> DVExpiryEmphasis? {
    SecretExpiryStatus(expiresAt: secret.expiresAt)?.emphasis
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

    case .all, .liked, .notice, .expired, .project:
      Button("Add to Project") {
        store.send(.didTapAddToProject(id: secret.id))
      }
      Button("Delete", role: .destructive) {
        store.send(.didTapDelete(id: secret.id))
      }
    }
  }

  /// divider 위: 정렬 기준(시간/만료/이름). divider 아래: 방향(오름/내림차순).
  /// `Menu`가 바깥 클릭·ESC·포커스 상실 처리를 대신하므로 이 화면은 두 축의 값만 계산하면 된다.
  @ViewBuilder
  private var sortMenuContent: some View {
    Picker("Sort by", selection: sortKeyBinding) {
      Text("Time").tag(SecretQuery.Sort.Key.time)
      Text("Expiry").tag(SecretQuery.Sort.Key.expiry)
      Text("Name").tag(SecretQuery.Sort.Key.name)
    }
    .pickerStyle(.inline)

    Divider()

    Picker("Direction", selection: sortDirectionBinding) {
      Text("Ascending").tag(SecretQuery.Sort.Direction.ascending)
      Text("Descending").tag(SecretQuery.Sort.Direction.descending)
    }
    .pickerStyle(.inline)
  }

  private var sortKeyBinding: Binding<SecretQuery.Sort.Key> {
    Binding(
      get: { store.sort.key },
      set: { store.send(.didSelectSort(SecretQuery.Sort(key: $0, direction: store.sort.direction))) }
    )
  }

  private var sortDirectionBinding: Binding<SecretQuery.Sort.Direction> {
    Binding(
      get: { store.sort.direction },
      set: { store.send(.didSelectSort(SecretQuery.Sort(key: store.sort.key, direction: $0))) }
    )
  }

  private var errorView: some View {
    VStack(spacing: 12) {
      Spacer()
      Image(systemName: "exclamationmark.triangle")
        .dvFont(.bodyLG)
        .foregroundStyle(Color.dv(.gray400))
      Text("Failed to load the list")
        .dvFont(.bodyMD)
        .foregroundStyle(Color.dv(.gray500))
      DVButton(titleText: "Retry", style: .secondary) {
        store.send(.didTapRetry)
      }
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var emptyView: some View {
    VStack(spacing: 12) {
      Spacer()
      Text("No secrets")
        .dvFont(.bodyMD)
        .foregroundStyle(Color.dv(.gray400))
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    case .notice: return "Notice"
    case .expired: return "Expired"
    case .deleted: return "Deleted"
    case .project: return store.projectName ?? "Project"
    }
  }

  /// Notice/Expired/Deleted는 정렬이 필요 없는 화면이라 정렬 UI 자체를 숨긴다.
  /// Notice는 항상 만료 임박 순으로 고정되므로(`SecretListFeature.State.query`) 사용자가 바꿀 이유가 없다.
  private var showsSort: Bool {
    switch store.collection {
    case .all, .liked:
      return true
    case .notice, .expired, .deleted, .project:
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

// MARK: - ExpiryBucket

/// Expired 탭의 섹션 구분. 경계는 `SecretExpiryPolicy`의 upcoming/listing window를 그대로 쓴다.

private enum ExpiryBucket: CaseIterable, Identifiable {
  case expired
  case within7Days
  case within30Days

  var id: Self { self }

  var title: String {
    switch self {
    case .expired: return "Expired"
    case .within7Days: return "Expires in 7 days"
    case .within30Days: return "Expires in 30 days"
    }
  }

  func contains(_ expiresAt: Date?, referenceDate: Date) -> Bool {
    guard let expiresAt else { return false }
    // Notice 탭(`noticeWindowDays`)과 같은 값에서 파생된다.
    let sevenDaysOut = referenceDate.addingTimeInterval(
      TimeInterval(SecretExpiryPolicy.upcomingWindowDays) * 86_400
    )
    let thirtyDaysOut = referenceDate.addingTimeInterval(
      TimeInterval(SecretExpiryPolicy.listingWindowDays) * 86_400
    )

    switch self {
    case .expired:
      return expiresAt < referenceDate
    case .within7Days:
      return expiresAt >= referenceDate && expiresAt <= sevenDaysOut
    case .within30Days:
      return expiresAt > sevenDaysOut && expiresAt <= thirtyDaysOut
    }
  }
}

// MARK: - Preview

#if DEBUG

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

#Preview("Notice - 정렬 없음, 만료 임박 뱃지만") {
  SecretListView(
    store: Store(initialState: SecretListFeature.State(collection: .notice(referenceDate: .now))) {
      SecretListFeature()
    } withDependencies: {
      $0.secretClient = .previewValue
    }
  )
  .frame(width: 300, height: 500)
}

#Preview("Expired - Expired/7일/30일 섹션") {
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

#Preview("Project - CheerLot에 속한 Secret만") {
  SecretListView(
    store: Store(
      initialState: SecretListFeature.State(
        collection: .project(id: [Project].preview[0].id),
        projectName: [Project].preview[0].name
      )
    ) {
      SecretListFeature()
    } withDependencies: {
      $0.secretClient = .previewValue
    }
  )
  .frame(width: 300, height: 500)
}

#endif
