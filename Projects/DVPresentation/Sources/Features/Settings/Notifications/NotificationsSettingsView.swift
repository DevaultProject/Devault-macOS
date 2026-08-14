// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - ExpiryAlertDayOption

private struct ExpiryAlertDayOption: Identifiable, Hashable {
  let id: Int
  let label: String

  static let all: [ExpiryAlertDayOption] = [
    ExpiryAlertDayOption(id: 30, label: String.module("30 days before expiration")),
    ExpiryAlertDayOption(id: 7, label: String.module("7 days before expiration")),
    ExpiryAlertDayOption(id: 1, label: String.module("1 day before expiration")),
    ExpiryAlertDayOption(id: 0, label: String.module("On the day of expiration")),
  ]
}

struct NotificationsSettingsView: View {

  @Bindable var store: StoreOf<NotificationSettingsFeature>

  var body: some View {
    SettingsScrollContainer {
      if !store.isNotificationPermissionGranted {
        permissionBanner
      }

      SettingsSection(title: String.module("Expiration Alerts")) {
        SettingsToggleRow(
          title: String.module("Enable expiration alerts"),
          isOn: Binding(
            get: { store.isExpiryAlertsEnabled },
            set: { store.send(.didToggleExpiryAlerts($0)) }
          )
        )
        if store.isExpiryAlertsEnabled {
          HStack {
            Text(.module("Alert timing"))
              .dvFont(.bodyLG)
              .foregroundStyle(Color.dv(.gray900))
            Spacer()
            DVMultiSelectDropdown(
              String.module("Select timing"),
              items: ExpiryAlertDayOption.all,
              selection: Binding(
                get: { store.expiryAlertDaysBefore },
                set: { store.send(.didChangeExpiryAlertDaysBefore($0)) }
              ),
              label: \.label
            )
          }
          .padding(.vertical, 8)
        }
      }

      SettingsSection(title: String.module("Security Alerts")) {
        SettingsToggleRow(
          title: String.module("Alert on repeated authentication failures"),
          isOn: Binding(
            get: { store.isAuthFailureAlertEnabled },
            set: { store.send(.didToggleAuthFailureAlert($0)) }
          )
        )
        SettingsToggleRow(
          title: String.module("Alert on repeated clipboard copies"),
          isOn: Binding(
            get: { store.isClipboardAbnormalAccessAlertEnabled },
            set: { store.send(.didToggleClipboardAbnormalAccessAlert($0)) }
          )
        )
      }
    }
    .task { store.send(.task) }
  }

  private var permissionBanner: some View {
    HStack(spacing: 12) {
      Image(systemName: "bell.slash.fill")
        .foregroundStyle(Color.dv(.warning))
      VStack(alignment: .leading, spacing: 2) {
        Text(.module("Notifications are turned off"))
          .dvFont(.bodyLG)
          .foregroundStyle(Color.dv(.gray900))
        Text(.module("System notification permission is required for these alerts to appear."))
          .dvFont(.captionMDRegular)
          .foregroundStyle(Color.dv(.gray600))
      }
      Spacer()
      Button(String.module("Open System Settings")) {
        store.send(.didTapOpenNotificationSettings)
      }
      .buttonStyle(.plain)
      .dvFont(.captionMDSemibold)
      .foregroundStyle(Color.dv(.vaultGreen))
    }
    .padding(12)
    .background(RoundedRectangle(cornerRadius: 8).fill(Color.dv(.gray100)))
  }
}
