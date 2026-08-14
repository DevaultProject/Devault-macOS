// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

struct ICloudSettingsView: View {

  @Bindable var store: StoreOf<ICloudSettingsFeature>

  var body: some View {
    SettingsScrollContainer {
      SettingsSection(title: String.module("iCloud Sync")) {
        SettingsToggleRow(
          title: String.module("Use iCloud Sync"),
          description: String.module("Sync your secrets across your Apple devices, end-to-end encrypted."),
          isOn: Binding(
            get: { store.isSyncEnabled },
            set: { store.send(.didToggleSync($0)) }
          )
        )
        .disabled(store.isTogglingSync)

        if store.showsRestartBanner {
          restartBanner
        }

        statusCard
      }
    }
    .task { store.send(.task) }
    .alert($store.scope(state: \.alert, action: \.alert))
  }

  private var restartBanner: some View {
    Text(.module("Restart DeVault to apply this change."))
      .dvFont(.captionMDRegular)
      .foregroundStyle(Color.dv(.warning))
      .padding(.vertical, 4)
  }

  private var statusCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemName: store.isSyncEnabled ? "checkmark.icloud.fill" : "icloud.slash")
          .foregroundStyle(store.isSyncEnabled ? Color.dv(.vaultGreen) : Color.dv(.gray500))
          .accessibilityHidden(true)
        Text(store.isSyncEnabled ? String.module("Connected") : String.module("Not Connected"))
          .dvFont(.bodyLG)
          .foregroundStyle(Color.dv(.gray900))
        Spacer()
        if store.isSyncEnabled {
          Button(String.module("Sync Now")) {
            store.send(.didTapSyncNow)
          }
          .buttonStyle(.plain)
          .dvFont(.captionMDSemibold)
          .foregroundStyle(Color.dv(.vaultGreen))
        }
      }

      if store.isSyncEnabled {
        if let lastSyncedAt = store.lastSyncedAt {
          Text(String.module("Last synced: \(lastSyncedAt.formatted(date: .abbreviated, time: .shortened))"))
            .dvFont(.captionMDRegular)
            .foregroundStyle(Color.dv(.gray600))
        }
        if let secretCount = store.syncedSecretCount {
          Text(String.module("Synced secrets: \(secretCount)"))
            .dvFont(.captionMDRegular)
            .foregroundStyle(Color.dv(.gray600))
        }
        if let projectCount = store.syncedProjectCount {
          Text(String.module("Synced projects: \(projectCount)"))
            .dvFont(.captionMDRegular)
            .foregroundStyle(Color.dv(.gray600))
        }
      } else {
        Text(.module("Turn on iCloud Sync to sync secrets across devices."))
          .dvFont(.captionMDRegular)
          .foregroundStyle(Color.dv(.gray600))
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 8).fill(Color.dv(.gray100)))
  }
}
