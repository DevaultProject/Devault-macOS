// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - SettingsView

struct SettingsView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<SettingsFeature>

  // MARK: - Body

  var body: some View {
    NavigationSplitView {
      sidebarColumn
    } detail: {
      detailColumn
    }
    .navigationSplitViewStyle(.balanced)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        closeButton
      }
    }
  }
}

// MARK: - Subviews

extension SettingsView {

  private var sidebarColumn: some View {
    List(
      SettingsCategory.allCases,
      id: \.self,
      selection: Binding(
        get: { store.selectedCategory },
        set: { newValue in
          if let newValue { store.send(.didSelectCategory(newValue)) }
        }
      )
    ) { category in
      Label(category.title, systemImage: category.icon)
    }
    .navigationTitle(String.module("Settings"))
    .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
  }

  @ViewBuilder
  private var detailColumn: some View {
    switch store.selectedCategory {
    case .general:
      GeneralSettingsView(store: store.scope(state: \.general, action: \.general))
    case .security:
      SecuritySettingsView(store: store.scope(state: \.security, action: \.security))
    case .icloud:
      ICloudSettingsView(store: store.scope(state: \.icloud, action: \.icloud))
    case .notifications: NotificationsSettingsView()
    case .shortcuts:     ShortcutsSettingsView()
    case .data:          DataSettingsView()
    case .about:         AboutSettingsView()
    }
  }

  private var closeButton: some View {
    Button {
      store.send(.didTapClose)
    } label: {
      Image(systemName: "xmark.circle.fill")
        .foregroundStyle(Color.dv(.gray500))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(String.module("Close Settings"))
  }
}

// MARK: - Preview

#Preview {
  SettingsView(
    store: Store(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }
  )
  .frame(width: 720, height: 480)
}
