// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVData
import DVDomain
import DVPresentation

extension AppSecurityClient: @retroactive DependencyKey {
  public static let liveValue: AppSecurityClient = {
    let useCase: any SecuritySettingsUseCase = SecuritySettingsUseCaseImpl(
      repository: LiveRepositories.settings
    )
    let inactivityUseCase: any MonitorAppInactivityUseCase = MonitorAppInactivityUseCaseImpl(
      service: AppInactivityMonitorServiceImpl(),
      repository: LiveRepositories.settings
    )

    return AppSecurityClient(
      isRequireAuthOnLaunchEnabled: {
        useCase.isRequireAuthOnLaunchEnabled()
      },
      inactivityTimeoutStream: {
        inactivityUseCase.timeoutStream()
      }
    )
  }()
}
