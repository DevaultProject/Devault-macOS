// Copyright © 2026 Devault. All rights reserved

import ServiceManagement

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
      }
    )
  }()
}
