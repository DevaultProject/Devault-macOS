// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - NotificationSettingsFeature

@Reducer
public struct NotificationSettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var isExpiryAlertsEnabled = true
    var expiryAlertDaysBefore = Set(ExpiryAlertDay.allCases)
    var isAuthFailureAlertEnabled = true
    var isClipboardAbnormalAccessAlertEnabled = true
    var isNotificationPermissionGranted = true
    @Presents var alert: AlertState<Action.Alert>?

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task
    case didTapExpiryAlertDay(ExpiryAlertDay)
    case didTapOpenNotificationSettings

    // MARK: - Internal

    case permissionResponse(Bool)
    case expiryNotificationsUpdateFailed

    // MARK: - Child

    case alert(PresentationAction<Alert>)

    public enum Alert: Equatable {}
  }

  // MARK: - Dependencies

  @Dependency(\.notificationSettingsClient) var notificationSettingsClient

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .task:
        state.isExpiryAlertsEnabled = notificationSettingsClient.isExpiryAlertsEnabled()
        state.expiryAlertDaysBefore = Set(
          notificationSettingsClient.expiryAlertDaysBefore().compactMap(ExpiryAlertDay.init)
        )
        state.isAuthFailureAlertEnabled = notificationSettingsClient.isAuthFailureAlertEnabled()
        state.isClipboardAbnormalAccessAlertEnabled = notificationSettingsClient.isClipboardAbnormalAccessAlertEnabled()
        return .run { send in
          let granted = await notificationSettingsClient.isPermissionGranted()
          await send(.permissionResponse(granted))
        }

      case .permissionResponse(let granted):
        state.isNotificationPermissionGranted = granted
        return .none

      case .binding(\.isExpiryAlertsEnabled):
        let enabled = state.isExpiryAlertsEnabled
        return .run { send in
          do {
            try await notificationSettingsClient.setExpiryAlertsEnabled(enabled)
          } catch {
            await send(.expiryNotificationsUpdateFailed)
          }
        }

      case .binding(\.isAuthFailureAlertEnabled):
        let enabled = state.isAuthFailureAlertEnabled
        return .run { _ in notificationSettingsClient.setAuthFailureAlertEnabled(enabled) }

      case .binding(\.isClipboardAbnormalAccessAlertEnabled):
        let enabled = state.isClipboardAbnormalAccessAlertEnabled
        return .run { _ in notificationSettingsClient.setClipboardAbnormalAccessAlertEnabled(enabled) }

      case .binding:
        return .none

      case .expiryNotificationsUpdateFailed:
        state.alert = AlertState {
          TextState(String.module("Couldn't update expiration alerts"))
        } actions: {
          ButtonState(role: .cancel) { TextState(String.module("OK")) }
        } message: {
          TextState(String.module("The setting was saved, but existing notifications couldn't be updated. Please try again."))
        }
        return .none

      case .didTapExpiryAlertDay(let day):
        if state.expiryAlertDaysBefore.contains(day) {
          state.expiryAlertDaysBefore.remove(day)
        } else {
          state.expiryAlertDaysBefore.insert(day)
        }
        let days = state.expiryAlertDaysBefore.map(\.rawValue).sorted(by: >)
        return .run { send in
          do {
            try await notificationSettingsClient.setExpiryAlertDaysBefore(days)
          } catch {
            await send(.expiryNotificationsUpdateFailed)
          }
        }

      case .didTapOpenNotificationSettings:
        return .run { _ in notificationSettingsClient.openSystemSettings() }

      case .alert:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}
