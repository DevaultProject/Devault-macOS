// Copyright © 2026 Devault. All rights reserved

import AppKit
import ServiceManagement
import UserNotifications

import ComposableArchitecture
import DVData
import DVDomain
import DVPresentation

extension SettingsClient: @retroactive DependencyKey {
  public static let liveValue: SettingsClient = {
    let generalUseCase: any GeneralSettingsUseCase = GeneralSettingsUseCaseImpl(
      repository: LiveRepositories.settings
    )
    let securityUseCase: any SecuritySettingsUseCase = SecuritySettingsUseCaseImpl(
      repository: LiveRepositories.settings
    )
    let iCloudSyncSettings: any ICloudSyncSettingsUseCase = ICloudSyncSettingsUseCaseImpl(
      repository: LiveRepositories.settings
    )
    let notificationUseCase: any NotificationSettingsUseCase = NotificationSettingsUseCaseImpl(
      repository: LiveRepositories.settings
    )

    return SettingsClient(
      isLaunchAtLoginEnabled: {
        generalUseCase.isLaunchAtLoginEnabled()
      },
      setLaunchAtLoginEnabled: { enabled in
        if enabled {
          try SMAppService.mainApp.register()
        } else {
          try SMAppService.mainApp.unregister()
        }
        generalUseCase.setLaunchAtLoginEnabled(enabled)
      },
      defaultEnvironment: {
        generalUseCase.defaultEnvironment()
      },
      setDefaultEnvironment: { rawValue in
        generalUseCase.setDefaultEnvironment(rawValue)
      },
      isRequireAuthOnLaunchEnabled: {
        securityUseCase.isRequireAuthOnLaunchEnabled()
      },
      setRequireAuthOnLaunchEnabled: { enabled in
        securityUseCase.setRequireAuthOnLaunchEnabled(enabled)
      },
      isRequireAuthToCopyEnabled: {
        securityUseCase.isRequireAuthToCopyEnabled()
      },
      setRequireAuthToCopyEnabled: { enabled in
        securityUseCase.setRequireAuthToCopyEnabled(enabled)
      },
      autoLockMinutes: {
        securityUseCase.autoLockMinutes()
      },
      setAutoLockMinutes: { minutes in
        securityUseCase.setAutoLockMinutes(minutes)
      },
      isAutoClearClipboardEnabled: {
        securityUseCase.isAutoClearClipboardEnabled()
      },
      setAutoClearClipboardEnabled: { enabled in
        securityUseCase.setAutoClearClipboardEnabled(enabled)
      },
      autoClearClipboardDelaySeconds: {
        securityUseCase.autoClearClipboardDelaySeconds()
      },
      setAutoClearClipboardDelaySeconds: { seconds in
        securityUseCase.setAutoClearClipboardDelaySeconds(seconds)
      },
      isHideDuringScreenRecordingEnabled: {
        securityUseCase.isHideDuringScreenRecordingEnabled()
      },
      setHideDuringScreenRecordingEnabled: { enabled in
        securityUseCase.setHideDuringScreenRecordingEnabled(enabled)
      },
      isICloudSyncEnabled: {
        iCloudSyncSettings.isEnabled()
      },
      setICloudSyncEnabled: { enabled in
        iCloudSyncSettings.setEnabled(enabled)
      },
      openICloudSystemSettings: {
        // OnboardingClient+Live.swift와 동일한 딥링크. AppleIDPrefPane이 현재의 legacy bundle identifier.
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane?icloud") else { return }
        NSWorkspace.shared.open(url)
      },
      isExpiryAlertsEnabled: {
        notificationUseCase.isExpiryAlertsEnabled()
      },
      setExpiryAlertsEnabled: { enabled in
        notificationUseCase.setExpiryAlertsEnabled(enabled)
      },
      expiryAlertDaysBefore: {
        notificationUseCase.expiryAlertDaysBefore()
      },
      setExpiryAlertDaysBefore: { days in
        notificationUseCase.setExpiryAlertDaysBefore(days)
      },
      isAuthFailureAlertEnabled: {
        notificationUseCase.isAuthFailureAlertEnabled()
      },
      setAuthFailureAlertEnabled: { enabled in
        notificationUseCase.setAuthFailureAlertEnabled(enabled)
      },
      isClipboardAbnormalAccessAlertEnabled: {
        notificationUseCase.isClipboardAbnormalAccessAlertEnabled()
      },
      setClipboardAbnormalAccessAlertEnabled: { enabled in
        notificationUseCase.setClipboardAbnormalAccessAlertEnabled(enabled)
      },
      isNotificationPermissionGranted: {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
      },
      openNotificationSystemSettings: {
        // legacyBundleIdentifier(NotificationsSettings.appex) 확인 완료 — 실기 QA로 검증됨.
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") else { return }
        NSWorkspace.shared.open(url)
      },
      deleteAllData: {
        let useCase: any DeleteAllDataUseCase = DeleteAllDataUseCaseImpl(
          secretRepository: LiveRepositories.secret,
          projectRepository: LiveRepositories.project,
          authenticateUseCase: LiveUseCases.authenticate
        )
        try await useCase.execute()
      }
    )
  }()
}
