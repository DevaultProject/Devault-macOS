// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

struct GeneralSettingsView: View {

  @Bindable var store: StoreOf<GeneralSettingsFeature>

  var body: some View {
    SettingsScrollContainer {
      SettingsSection(title: String.module("Startup")) {
        SettingsToggleRow(
          title: String.module("Launch DeVault at login"),
          description: String.module("Automatically starts DeVault when you log in to your Mac."),
          isOn: Binding(
            get: { store.isLaunchAtLoginEnabled },
            set: { store.send(.didToggleLaunchAtLogin($0)) }
          )
        )
      }

      SettingsSection(title: String.module("Defaults")) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(.module("Default environment"))
              .dvFont(.bodyLG)
              .foregroundStyle(Color.dv(.gray900))
            Text(.module("Automatically applied when creating a new secret."))
              .dvFont(.captionMDRegular)
              .foregroundStyle(Color.dv(.gray600))
          }
          Spacer()
          environmentDropdown
        }
        .padding(.vertical, 8)
      }
    }
    .task { store.send(.task) }
  }

  private var environmentDropdown: some View {
    DVDropdown(store.defaultEnvironment.map { String(localized: $0.displayName) } ?? String.module("None")) {
      Button(String.module("None")) {
        store.send(.didSelectDefaultEnvironment(nil))
      }
      Divider()
      ForEach(SecretEnvironment.allCases, id: \.self) { environment in
        Button(String(localized: environment.displayName)) {
          store.send(.didSelectDefaultEnvironment(environment))
        }
      }
    }
  }
}
