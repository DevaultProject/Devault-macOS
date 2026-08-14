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

      SettingsSection(title: String.module("Auto-Lock")) {
        HStack {
          Text(.module("Lock after inactivity"))
            .dvFont(.bodyLG)
            .foregroundStyle(Color.dv(.gray900))
          Spacer()
          autoLockDropdown
        }
        .padding(.vertical, 8)
      }

      SettingsSection(title: String.module("Clipboard")) {
        SettingsToggleRow(
          title: String.module("Auto-clear clipboard"),
          isOn: Binding(
            get: { store.isAutoClearClipboardEnabled },
            set: { store.send(.didToggleAutoClearClipboard($0)) }
          )
        )
        if store.isAutoClearClipboardEnabled {
          HStack {
            Text(.module("Clear after"))
              .dvFont(.bodyLG)
              .foregroundStyle(Color.dv(.gray900))
            Spacer()
            autoClearClipboardDropdown
          }
          .padding(.vertical, 8)
        }
      }

      SettingsSection(title: String.module("Screen Protection")) {
        SettingsToggleRow(
          title: String.module("Hide values during screen recording"),
          isOn: Binding(
            get: { store.isHideDuringScreenRecordingEnabled },
            set: { store.send(.didToggleHideDuringScreenRecording($0)) }
          )
        )
      }
    }
    .task { store.send(.task) }
  }

  private var autoLockDropdown: some View {
    DVDropdown(Self.autoLockLabel(for: store.autoLockMinutes)) {
      ForEach(Self.autoLockOptions, id: \.self) { minutes in
        Button(Self.autoLockLabel(for: minutes)) {
          store.send(.didSelectAutoLockMinutes(minutes))
        }
      }
    }
  }

  private var autoClearClipboardDropdown: some View {
    DVDropdown(Self.autoClearClipboardLabel(for: store.autoClearClipboardDelaySeconds)) {
      ForEach(Self.autoClearClipboardOptions, id: \.self) { seconds in
        Button(Self.autoClearClipboardLabel(for: seconds)) {
          store.send(.didSelectAutoClearClipboardDelay(seconds))
        }
      }
    }
  }

  private static let autoLockOptions = [1, 3, 5, 15, 30, 0]
  private static let autoClearClipboardOptions = [15, 30, 60, 300]

  private static func autoLockLabel(for minutes: Int) -> String {
    minutes == 0 ? String.module("Never") : String.module("\(minutes) min")
  }

  private static func autoClearClipboardLabel(for seconds: Int) -> String {
    seconds < 60 ? String.module("\(seconds) sec") : String.module("\(seconds / 60) min")
  }
}
