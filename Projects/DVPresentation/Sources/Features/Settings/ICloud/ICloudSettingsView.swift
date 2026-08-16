// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

struct ICloudSettingsView: View {

  @Bindable var store: StoreOf<ICloudSettingsFeature>

  var body: some View {
    content
      .task { await store.send(.task).finish() }
      .alert($store.scope(state: \.alert, action: \.alert))
  }
}

// MARK: - Subviews

extension ICloudSettingsView {

  private var content: some View {
    SettingsDetailContainer(title: String.module("iCloud")) {
      SettingsSection(title: String.module("iCloud Sync")) {
        SettingsToggleRow(
          title: String.module("Use iCloud Sync"),
          description: String.module("Sync your secrets across your Apple devices, end-to-end encrypted."),
          isOn: $store.isSyncEnabled
        )
        .disabled(store.isTogglingSync)

      }

      SettingsSection(title: String.module("Status")) {
        statusRows
      }
    }
  }

  @ViewBuilder
  private var statusRows: some View {
    if store.isSyncEnabled {
      SettingsButtonRow(
        title: String.module("Connected"),
        buttonTitle: String.module("Sync Now"),
        systemImage: "checkmark.icloud",
        iconColor: Color.dv(.vaultGreen)
      ) {
        store.send(.didTapSyncNow)
      }
    } else {
      SettingsValueRow(
        title: String.module("Not Connected"),
        systemImage: "icloud.slash",
        iconColor: Color.dv(.gray500)
      )
    }

    if store.isSyncEnabled {
      SettingsValueRow(
        title: String.module("Last synced"),
        value: store.lastSyncedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—"
      )
      SettingsValueRow(
        title: String.module("Synced secrets"),
        value: store.syncedSecretCount.map { String($0) } ?? "—"
      )
      SettingsValueRow(
        title: String.module("Synced projects"),
        value: store.syncedProjectCount.map { String($0) } ?? "—"
      )
    } else {
      Text(.module("Turn on iCloud Sync to sync secrets across devices."))
        .dvFont(.captionMDRegular)
        .foregroundStyle(Color.dv(.gray600))
        .settingsRowLayout()
    }
  }
}

// MARK: - Preview

#Preview("iCloud") {
  SettingsDetailPreview {
    ICloudSettingsView(
      store: Store(initialState: ICloudSettingsFeature.State()) {
        ICloudSettingsFeature()
      } withDependencies: {
        $0.iCloudSettingsClient = .previewValue
        $0.iCloudSettingsClient.isEnabled = { true }
        $0.iCloudSettingsClient.lastSyncedAt = {
          Date(timeIntervalSince1970: 1_723_745_800)
        }
        $0.iCloudSettingsClient.syncedSecretCount = { 24 }
        $0.iCloudSettingsClient.syncedProjectCount = { 3 }
      }
    )
  }
}
