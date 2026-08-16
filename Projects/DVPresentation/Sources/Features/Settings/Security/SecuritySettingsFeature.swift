// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - SecuritySettingsFeature

@Reducer
public struct SecuritySettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var isRequireAuthOnLaunchEnabled = true
    var isRequireAuthToCopyEnabled = true
    var isAutoLockEnabled = true
    var autoLockInterval: AutoLockInterval = .fiveMinutes
    var isAutoClearClipboardEnabled = true
    var clipboardClearDelay: ClipboardClearDelay = .thirtySeconds
    var isWindowCaptureProtectionEnabled = true

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task
  }

  // MARK: - Dependencies

  @Dependency(\.securitySettingsClient) var securitySettingsClient

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .task:
        state.isRequireAuthOnLaunchEnabled = securitySettingsClient.isRequireAuthOnLaunchEnabled()
        state.isRequireAuthToCopyEnabled = securitySettingsClient.isRequireAuthToCopyEnabled()
        state.isAutoLockEnabled = securitySettingsClient.isAutoLockEnabled()
        state.autoLockInterval = AutoLockInterval(
          rawValue: securitySettingsClient.autoLockMinutes()
        ) ?? .fiveMinutes
        state.isAutoClearClipboardEnabled = securitySettingsClient.isAutoClearClipboardEnabled()
        state.clipboardClearDelay = ClipboardClearDelay(
          rawValue: securitySettingsClient.autoClearClipboardDelaySeconds()
        ) ?? .thirtySeconds
        state.isWindowCaptureProtectionEnabled = securitySettingsClient.isWindowCaptureProtectionEnabled()
        return .none

      case .binding(\.isRequireAuthOnLaunchEnabled):
        let enabled = state.isRequireAuthOnLaunchEnabled
        return .run { _ in securitySettingsClient.setRequireAuthOnLaunchEnabled(enabled) }

      case .binding(\.isRequireAuthToCopyEnabled):
        let enabled = state.isRequireAuthToCopyEnabled
        return .run { _ in securitySettingsClient.setRequireAuthToCopyEnabled(enabled) }

      case .binding(\.isAutoLockEnabled):
        let enabled = state.isAutoLockEnabled
        return .run { _ in securitySettingsClient.setAutoLockEnabled(enabled) }

      case .binding(\.autoLockInterval):
        let interval = state.autoLockInterval
        return .run { _ in securitySettingsClient.setAutoLockMinutes(interval.rawValue) }

      case .binding(\.isAutoClearClipboardEnabled):
        let enabled = state.isAutoClearClipboardEnabled
        return .run { _ in securitySettingsClient.setAutoClearClipboardEnabled(enabled) }

      case .binding(\.clipboardClearDelay):
        let delay = state.clipboardClearDelay
        return .run { _ in securitySettingsClient.setAutoClearClipboardDelaySeconds(delay.rawValue) }

      case .binding(\.isWindowCaptureProtectionEnabled):
        let enabled = state.isWindowCaptureProtectionEnabled
        return .run { _ in securitySettingsClient.setWindowCaptureProtectionEnabled(enabled) }

      case .binding:
        return .none
      }
    }
  }
}
