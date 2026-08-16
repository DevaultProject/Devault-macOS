// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

struct SecuritySettingsView: View {

  @Bindable var store: StoreOf<SecuritySettingsFeature>

  var body: some View {
    content
      .task { await store.send(.task).finish() }
  }
}

// MARK: - Subviews

extension SecuritySettingsView {

  private var content: some View {
    SettingsDetailContainer(title: String.module("Security")) {
      SettingsSection(title: String.module("Authentication")) {
        SettingsToggleRow(
          title: String.module("Require authentication on app launch"),
          isOn: $store.isRequireAuthOnLaunchEnabled
        )
        SettingsToggleRow(
          title: String.module("Require authentication to copy secret"),
          isOn: $store.isRequireAuthToCopyEnabled
        )
      }

      SettingsSection(title: String.module("Auto-Lock")) {
        SettingsToggleRow(
          title: String.module("Auto-lock"),
          isOn: $store.isAutoLockEnabled
        )
        if store.isAutoLockEnabled {
          SettingsPickerRow(
            title: String.module("Lock after inactivity"),
            selection: $store.autoLockInterval
          ) {
            ForEach(AutoLockInterval.allCases, id: \.self) { interval in
              Text(interval.displayName)
                .tag(interval)
            }
          }
        }
      }

      SettingsSection(title: String.module("Clipboard")) {
        SettingsToggleRow(
          title: String.module("Auto-clear clipboard"),
          isOn: $store.isAutoClearClipboardEnabled
        )
        if store.isAutoClearClipboardEnabled {
          SettingsPickerRow(
            title: String.module("Clear after"),
            selection: $store.clipboardClearDelay
          ) {
            ForEach(ClipboardClearDelay.allCases, id: \.self) { delay in
              Text(delay.displayName)
                .tag(delay)
            }
          }
        }
      }

      SettingsSection(title: String.module("Screen Protection")) {
        SettingsToggleRow(
          title: String.module("Protect the entire app window"),
          description: String.module(
            "Excludes the DeVault window from screenshots, screen recordings, and screen sharing."
          ),
          isOn: $store.isWindowCaptureProtectionEnabled
        )
      }
    }
  }

}

// MARK: - Preview

#Preview("Security") {
  SettingsDetailPreview {
    SecuritySettingsView(
      store: Store(initialState: SecuritySettingsFeature.State()) {
        SecuritySettingsFeature()
      } withDependencies: {
        $0.securitySettingsClient = .previewValue
      }
    )
  }
}
