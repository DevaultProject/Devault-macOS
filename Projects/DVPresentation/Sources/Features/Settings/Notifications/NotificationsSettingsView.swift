// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign
import DVDomain

struct NotificationsSettingsView: View {

  @Bindable var store: StoreOf<NotificationSettingsFeature>

  var body: some View {
    content
      .task { await store.send(.task).finish() }
      .alert($store.scope(state: \.alert, action: \.alert))
  }
}

// MARK: - Subviews

extension NotificationsSettingsView {

  private var content: some View {
    SettingsDetailContainer(title: String.module("Notifications")) {
      if !store.isNotificationPermissionGranted {
        permissionBanner
      }

      SettingsSection(title: String.module("Expiration Alerts")) {
        SettingsToggleRow(
          title: String.module("Enable expiration alerts"),
          isOn: $store.isExpiryAlertsEnabled
        )
        if store.isExpiryAlertsEnabled {
          alertTimingOptions
        }
      }

      SettingsSection(title: String.module("Security Alerts")) {
        SettingsToggleRow(
          title: String.module("Alert on repeated authentication failures"),
          isOn: $store.isAuthFailureAlertEnabled
        )
        SettingsToggleRow(
          title: String.module("Alert on repeated clipboard copies"),
          isOn: $store.isClipboardAbnormalAccessAlertEnabled
        )
      }
    }
  }

  private var alertTimingOptions: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(.module("Alert timing"))
        .dvFont(.bodyLG)
        .foregroundStyle(Color.dv(.gray900))

      ForEach(ExpiryAlertDay.allCases) { option in
        Toggle(
          isOn: Binding(
            get: {
              store.expiryAlertDaysBefore.contains(option)
            },
            set: { isSelected in
              let wasSelected = store.expiryAlertDaysBefore.contains(option)
              guard isSelected != wasSelected else { return }
              store.send(.didTapExpiryAlertDay(option))
            }
          )
        ) {
          Text(option.displayName)
            .dvFont(.bodyMD)
            .foregroundStyle(Color.dv(.gray800))
        }
        .toggleStyle(.checkbox)
      }

      if store.isMultipleAlertDaysLocked {
        // 체크박스 자체는 계속 눌린다 — 누르면 페이월이 뜬다. 눌러 보기 전에 "다른 걸 추가로 누르면 페이월,
        // 바꾸고 싶으면 먼저 해제"라는 걸 미리 알려서 페이월을 오작동처럼 느끼지 않게 한다.
        Text(.module("The free plan allows one alert timing. To switch, uncheck the current one first."))
          .dvFont(.captionLG)
          .foregroundStyle(Color.dv(.gray600))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .settingsRowLayout()
  }

  private var permissionBanner: some View {
    SettingsButtonRow(
      title: String.module("Notifications are turned off"),
      description: String.module(
        "System notification permission is required for these alerts to appear."
      ),
      buttonTitle: String.module("Open System Settings"),
      systemImage: "bell.slash.fill",
      iconColor: Color.dv(.warning)
    ) {
      store.send(.didTapOpenNotificationSettings)
    }
    .padding(12)
    .background(RoundedRectangle(cornerRadius: 10).fill(Color.dv(.gray200)))
  }
}

// MARK: - Preview

#Preview("Notifications") {
  SettingsDetailPreview {
    NotificationsSettingsView(
      store: Store(initialState: NotificationSettingsFeature.State()) {
        NotificationSettingsFeature()
      } withDependencies: {
        $0.notificationSettingsClient = .previewValue
        $0.notificationSettingsClient.isPermissionGranted = { false }
      }
    )
  }
}
