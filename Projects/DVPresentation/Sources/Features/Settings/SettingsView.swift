// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - SettingsView

struct SettingsView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<SettingsFeature>
  @State private var isBackToAppHovered = false

  // MARK: - Body

  var body: some View {
    content
      .navigationSplitViewStyle(.balanced)
      .tint(Color.dv(.vaultGreen))
      .task { await store.send(.task).finish() }
  }
}

// MARK: - Subviews

extension SettingsView {

  private var content: some View {
    NavigationSplitView {
      sidebarColumn
    } detail: {
      detailColumn
    }
  }

  private var sidebarColumn: some View {
    List(
      selection: Binding<SettingsCategory?>(
        get: { store.selectedCategory },
        set: { newValue in
          if let newValue {
            store.send(.binding(.set(\.selectedCategory, newValue)))
          }
        }
      )
    ) {
      backToAppRow

      Text(.module("Settings"))
        .dvFont(.headingLG)
        .foregroundStyle(Color.dv(.gray900))
        .listRowSeparator(.hidden)

      devaultProRow

      Divider()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .listRowSeparator(.hidden)

      ForEach(SettingsCategory.allCases.filter { $0 != .devaultPro }, id: \.self) { category in
        settingsCategoryRow(category)
      }
    }
    .listStyle(.sidebar)
    // 메인 화면 사이드바와 같은 값으로 고정한다(`MainView.sidebarColumn`). 설정을 드나들 때
    // 사이드바 폭이 달라지지 않고, 범위를 없애 `.balanced`가 폭을 재분배할 여지도 남기지 않는다.
    .navigationSplitViewColumnWidth(
      min: WindowLayoutMetrics.sidebarWidth,
      ideal: WindowLayoutMetrics.sidebarWidth,
      max: WindowLayoutMetrics.sidebarWidth
    )
  }

  private var backToAppRow: some View {
    Button {
      store.send(.didTapClose)
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "arrow.left")
          .frame(width: 16, height: 16)
          .fontWeight(.medium)
          .accessibilityHidden(true)
        Text(.module("Back to App"))
          .dvFont(.bodyLG)
      }
      .padding(8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        isBackToAppHovered ? Color.dv(.gray200) : Color.clear,
        in: RoundedRectangle(cornerRadius: 8)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .foregroundStyle(isBackToAppHovered ? Color.dv(.gray900) : Color.dv(.gray700))
    .listRowSeparator(.hidden)
    .onHover { isBackToAppHovered = $0 }
    .dvAnimation(MotionMetrics.hover, value: isBackToAppHovered)
  }

  /// 다른 탭과 같은 기본 시스템 선택 색을 그대로 쓴다 — 여기만 따로 초록을 칠하지 않는다.
  /// "PRO" 배지는 실제로 구독 중일 때만 붙인다 — 미구독인데 배지를 보여주면 이미 구독한 것으로 오해한다.
  private var devaultProRow: some View {
    Label {
      HStack(spacing: 8) {
        Text(SettingsCategory.devaultPro.title)
          .dvFont(.bodyLG)
        if store.devaultPro.isPro {
          // DVChip은 내부적으로 Button이라 그대로 두면 포커스·클릭을 받는다 — 표시 전용
          // 배지라 allowsHitTesting(false)로 인터랙션을 막는다(DVChipsContainer와 동일 패턴).
          DVChip(String.module("PRO"))
            .allowsHitTesting(false)
        }
      }
    } icon: {
      Image(systemName: SettingsCategory.devaultPro.icon)
        .font(.system(size: 15, weight: .medium))
        .frame(width: 20, height: 20)
    }
    .padding(.vertical, 5)
    .tag(SettingsCategory.devaultPro)
  }

  /// Free면 iCloud 동기화 자체를 켤 수 없으니(``EntitlementClient/canEnableICloudSync``와 같은 게이트),
  /// 들어가 봤자 잠긴 화면만 보이는 탭을 아예 회색으로 죽이고 선택 못 하게 막는다.
  @ViewBuilder
  private func settingsCategoryRow(_ category: SettingsCategory) -> some View {
    let isLocked = category == .icloud && !store.devaultPro.isPro

    let label = Label {
      HStack(spacing: 8) {
        Text(category.title)
          .dvFont(.bodyLG)
        if isLocked {
          forProBadge
        }
      }
    } icon: {
      // 아이콘은 Label 바깥의 foregroundStyle을 안 따라가서 잠긴 상태에서만 직접 건다.
      // 나머지 행은 색을 강제하지 않아야 선택 시 시스템이 주는 흰색 하이라이트가 그대로 먹힌다.
      if isLocked {
        Image(systemName: category.icon)
          .font(.system(size: 15, weight: .medium))
          .frame(width: 20, height: 20)
          .foregroundStyle(Color.dv(.gray400))
      } else {
        Image(systemName: category.icon)
          .font(.system(size: 15, weight: .medium))
          .frame(width: 20, height: 20)
      }
    }
    .padding(.vertical, 5)
    .tag(category)

    if isLocked {
      // `.tag`만 빼면 macOS List가 tag 매칭과 무관하게 클릭 시 하이라이트를 잠깐 보여준다 —
      // `.selectionDisabled(true)`가 List 선택에서 이 행을 아예 제외하는 정식 API다.
      label
        .foregroundStyle(Color.dv(.gray400))
        .selectionDisabled(true)
    } else {
      label
    }
  }

  private var forProBadge: some View {
    Text(String.module("for PRO"))
      .dvFont(.captionMDSemibold)
      .foregroundStyle(Color.dv(.gray500))
      .padding(.horizontal, 8)
      .padding(.vertical, 2)
      .overlay(
        Capsule().stroke(Color.dv(.gray300), lineWidth: 1)
      )
  }

  private var detailColumn: some View {
    detailContent
      .frame(maxWidth: WindowLayoutMetrics.settingsDetailWidth, maxHeight: .infinity, alignment: .topLeading)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .dvScreenBackground()
  }

  @ViewBuilder
  private var detailContent: some View {
    switch store.selectedCategory {
    case .devaultPro:
      DevaultProSettingsView(store: store.scope(state: \.devaultPro, action: \.devaultPro))
    case .general:
      GeneralSettingsView(store: store.scope(state: \.general, action: \.general))
    case .security:
      SecuritySettingsView(store: store.scope(state: \.security, action: \.security))
    case .icloud:
      ICloudSettingsView(store: store.scope(state: \.icloud, action: \.icloud))
    case .notifications:
      NotificationsSettingsView(store: store.scope(state: \.notifications, action: \.notifications))
    case .shortcuts:
      ShortcutsSettingsView()
    case .data:
      DataSettingsView(store: store.scope(state: \.data, action: \.data))
    case .about:
      AboutSettingsView(store: store.scope(state: \.about, action: \.about))
    }
  }
}

// MARK: - Preview

#Preview {
  SettingsView(
    store: Store(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.generalSettingsClient = .previewValue
      $0.securitySettingsClient = .previewValue
      $0.iCloudSettingsClient = .previewValue
      $0.notificationSettingsClient = .previewValue
      $0.dataSettingsClient = .previewValue
      $0.aboutSettingsClient = .previewValue
    }
  )
  .frame(width: 1024, height: 680)
}
