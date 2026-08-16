// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

struct GeneralSettingsView: View {

  @Bindable var store: StoreOf<GeneralSettingsFeature>

  var body: some View {
    content
      .task { await store.send(.task).finish() }
  }
}

// MARK: - Subviews

extension GeneralSettingsView {

  private var content: some View {
    SettingsDetailContainer(title: String.module("General")) {
      SettingsSection(title: String.module("Startup")) {
        SettingsToggleRow(
          title: String.module("Launch DeVault at login"),
          description: String.module("Automatically starts DeVault when you log in to your Mac."),
          isOn: $store.isLaunchAtLoginEnabled
        )
      }

      SettingsSection(title: String.module("Defaults")) {
        SettingsPickerRow(
          title: String.module("Default environment"),
          description: String.module("Automatically applied when creating a new secret."),
          selection: $store.defaultEnvironment
        ) {
          ForEach(SecretEnvironment.allCases, id: \.self) { environment in
            Text(String(localized: environment.displayName))
              .tag(environment)
          }
        }
      }
    }
  }
}

// MARK: - Preview

#Preview("General") {
  SettingsDetailPreview {
    GeneralSettingsView(
      store: Store(initialState: GeneralSettingsFeature.State()) {
        GeneralSettingsFeature()
      } withDependencies: {
        $0.generalSettingsClient = .previewValue
      }
    )
  }
}
