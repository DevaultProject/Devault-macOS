// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - NotificationSettingsFeature

@Reducer
struct NotificationSettingsFeature {

  // MARK: - State

  @ObservableState
  struct State: Equatable {
    var isExpiryAlertsEnabled = true
    var expiryAlertDaysBefore: Set<Int> = [30, 7, 1, 0]
    var isAuthFailureAlertEnabled = true
    var isClipboardAbnormalAccessAlertEnabled = true
    var isNotificationPermissionGranted = true
  }

  // MARK: - Action

  enum Action: Equatable {
    case task
    case permissionResponse(Bool)
    case didToggleExpiryAlerts(Bool)
    case didChangeExpiryAlertDaysBefore(Set<Int>)
    case didToggleAuthFailureAlert(Bool)
    case didToggleClipboardAbnormalAccessAlert(Bool)
    case didTapOpenNotificationSettings
  }

  // MARK: - Dependencies

  @Dependency(\.settingsClient) var settingsClient

  // MARK: - Body

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        state.isExpiryAlertsEnabled = settingsClient.isExpiryAlertsEnabled()
        state.expiryAlertDaysBefore = Set(settingsClient.expiryAlertDaysBefore())
        state.isAuthFailureAlertEnabled = settingsClient.isAuthFailureAlertEnabled()
        state.isClipboardAbnormalAccessAlertEnabled = settingsClient.isClipboardAbnormalAccessAlertEnabled()
        return .run { send in
          let granted = await settingsClient.isNotificationPermissionGranted()
          await send(.permissionResponse(granted))
        }

      case .permissionResponse(let granted):
        state.isNotificationPermissionGranted = granted
        return .none

      case .didToggleExpiryAlerts(let enabled):
        state.isExpiryAlertsEnabled = enabled
        return .run { _ in settingsClient.setExpiryAlertsEnabled(enabled) }

      case .didChangeExpiryAlertDaysBefore(let days):
        state.expiryAlertDaysBefore = days
        return .run { _ in settingsClient.setExpiryAlertDaysBefore(Array(days)) }

      case .didToggleAuthFailureAlert(let enabled):
        state.isAuthFailureAlertEnabled = enabled
        return .run { _ in settingsClient.setAuthFailureAlertEnabled(enabled) }

      case .didToggleClipboardAbnormalAccessAlert(let enabled):
        state.isClipboardAbnormalAccessAlertEnabled = enabled
        return .run { _ in settingsClient.setClipboardAbnormalAccessAlertEnabled(enabled) }

      case .didTapOpenNotificationSettings:
        return .run { _ in settingsClient.openNotificationSystemSettings() }
      }
    }
  }
}
