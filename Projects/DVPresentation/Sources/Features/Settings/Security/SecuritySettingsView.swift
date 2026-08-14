// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

struct SecuritySettingsView: View {

  @Bindable var store: StoreOf<SecuritySettingsFeature>

  var body: some View {
    SettingsScrollContainer {
      SettingsSection(title: String.module("Authentication")) {
        SettingsToggleRow(
          title: String.module("Require authentication on app launch"),
          isOn: Binding(
            get: { store.isRequireAuthOnLaunchEnabled },
            set: { store.send(.didToggleRequireAuthOnLaunch($0)) }
          )
        )
        SettingsToggleRow(
          title: String.module("Require authentication to copy secret"),
          isOn: Binding(
            get: { store.isRequireAuthToCopyEnabled },
            set: { store.send(.didToggleRequireAuthToCopy($0)) }
          )
        )
      }
    }
    .task { store.send(.task) }
  }
}
