// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVData
import DVDomain
import DVPresentation

extension GeneralSettingsClient: @retroactive DependencyKey {
  public static let liveValue: GeneralSettingsClient = {
    let useCase: any GeneralSettingsUseCase = GeneralSettingsUseCaseImpl(
      repository: LiveRepositories.settings,
      launchAtLoginService: LaunchAtLoginServiceImpl()
    )

    return GeneralSettingsClient(
      launchAtLoginStatus: {
        useCase.launchAtLoginStatus()
      },
      setLaunchAtLoginEnabled: { enabled in
        try useCase.setLaunchAtLoginEnabled(enabled)
      },
      openLoginItemsSystemSettings: {
        useCase.openLoginItemsSystemSettings()
      },
      defaultEnvironment: {
        useCase.defaultEnvironment()
      },
      setDefaultEnvironment: { rawValue in
        useCase.setDefaultEnvironment(rawValue)
      }
    )
  }()
}
