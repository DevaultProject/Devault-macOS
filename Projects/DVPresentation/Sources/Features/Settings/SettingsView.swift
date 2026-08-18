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

      ForEach(SettingsCategory.allCases, id: \.self) { category in
        Label {
          Text(category.title)
            .dvFont(.bodyLG)
        } icon: {
          Image(systemName: category.icon)
            .font(.system(size: 15, weight: .medium))
            .frame(width: 20, height: 20)
        }
        .padding(.vertical, 5)
        .tag(category)
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
    .animation(MotionMetrics.hover, value: isBackToAppHovered)
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
