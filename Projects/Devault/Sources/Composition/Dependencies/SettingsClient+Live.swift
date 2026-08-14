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
      }
    )
  }()
}
