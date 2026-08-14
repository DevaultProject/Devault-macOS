// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

struct DataSettingsView: View {

  @Bindable var store: StoreOf<DataSettingsFeature>

  var body: some View {
    SettingsScrollContainer {
      SettingsSection(title: String.module("Reset")) {
        VStack(alignment: .leading, spacing: 8) {
          Text(.module("⚠️ This action cannot be undone."))
            .dvFont(.captionMDRegular)
            .foregroundStyle(Color.dv(.danger))
          DVButton(titleText: String.module("Delete All Data"), style: .secondary) {
            store.send(.didTapDeleteAllData)
          }
          .disabled(store.isDeleting)
        }
        .padding(.vertical, 8)
      }
    }
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}
