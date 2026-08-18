// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftUI

import ComposableArchitecture
import DVDesign

struct AboutSettingsView: View {

  @Bindable var store: StoreOf<AboutSettingsFeature>
  private static let licenseURL = URL(
    string: "https://github.com/DevaultProject/Devault-macOS/blob/develop/LICENSE"
  )

  var body: some View {
    content
      .task { await store.send(.task).finish() }
      .sheet(isPresented: $store.isShowingLicenses) {
        OpenSourceLicensesView()
      }
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
        // 서드파티 라이선스는 전문을 앱에 번들해 sheet로 보여준다.
        SettingsButtonRow(
          title: String.module("Open Source Licenses"),
          buttonTitle: String.module("View"),
          action: { store.send(.didTapOpenSourceLicenses) }
        )
      }

      SettingsSection(title: String.module("Support")) {
        SettingsLinkRow(
          title: String.module("Help"),
          linkTitle: String.module("Support Center"),
          destination: HelpMenuLink.help.url
        )
        SettingsLinkRow(
          title: String.module("Privacy Policy"),
          linkTitle: String.module("View"),
          destination: HelpMenuLink.privacyPolicy.url
        )
        SettingsLinkRow(
          title: String.module("Contact"),
          linkTitle: String.module("Email"),
          destination: HelpMenuLink.sendFeedback.url
        )
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
