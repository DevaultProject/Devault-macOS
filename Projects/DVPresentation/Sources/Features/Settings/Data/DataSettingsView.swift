// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

struct DataSettingsView: View {

  @Bindable var store: StoreOf<DataSettingsFeature>

  var body: some View {
    content
      .task { await store.send(.task).finish() }
      .alert($store.scope(state: \.alert, action: \.alert))
  }
}

// MARK: - Subviews

extension DataSettingsView {

  private var content: some View {
    SettingsDetailContainer(title: String.module("Data")) {
      SettingsSection(title: String.module("Reset")) {
        VStack(alignment: .leading, spacing: 10) {
          HStack(spacing: 2) {
            Image(systemName: "exclamationmark.triangle")
              .accessibilityHidden(true)
            Text(.module("This action cannot be undone."))
          }
          .foregroundStyle(Color.dv(.danger))
          .dvFont(.captionMDRegular)
          .accessibilityElement(children: .combine)
          if store.isICloudSyncEnabled {
            Text(.module("This will also delete data from iCloud and all synced devices."))
              .dvFont(.captionMDRegular)
              .foregroundStyle(Color.dv(.gray600))
              .fixedSize(horizontal: false, vertical: true)
          }
          DVButton(titleText: String.module("Delete All Data"), style: .secondary) {
            store.send(.didTapDeleteAllData)
          }
          .disabled(store.isDeleting)
        }
      }
    }
  }
}

// MARK: - Preview

#Preview("Data") {
  SettingsDetailPreview {
    DataSettingsView(
      store: Store(initialState: DataSettingsFeature.State()) {
        DataSettingsFeature()
      } withDependencies: {
        $0.dataSettingsClient = .previewValue
      }
    )
  }
}
