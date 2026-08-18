// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftUI

import ComposableArchitecture
import DVDesign

struct AboutSettingsView: View {

  let store: StoreOf<AboutSettingsFeature>
  private static let licenseURL = URL(
    string: "https://github.com/DevaultProject/Devault-macOS/blob/develop/LICENSE"
  )

  var body: some View {
    content
      .task { await store.send(.task).finish() }
  }
}

// MARK: - Subviews

extension AboutSettingsView {

  private var content: some View {
    SettingsDetailContainer(title: String.module("About")) {
      SettingsSection(title: String.module("Version")) {
        SettingsValueRow(
          title: String.module("DeVault"),
          value: store.version
        )
      }

      SettingsSection(title: String.module("Developer")) {
        SettingsValueRow(title: String.module("DeVault Team"))
      }

      SettingsSection(title: String.module("License")) {
        if let licenseURL = Self.licenseURL {
          SettingsLinkRow(
            title: String.module("MIT License"),
            linkTitle: String.module("View on GitHub"),
            destination: licenseURL
          )
        }
      }
    }
  }
}

// MARK: - Preview

#Preview("About") {
  SettingsDetailPreview {
    AboutSettingsView(
      store: Store(initialState: AboutSettingsFeature.State()) {
        AboutSettingsFeature()
      } withDependencies: {
        $0.aboutSettingsClient = .previewValue
      }
    )
  }
}
