// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import DVPresentation

extension DataSettingsClient: @retroactive DependencyKey {
  public static let liveValue: DataSettingsClient = {
    let useCase: any DataSettingsUseCase = DataSettingsUseCaseImpl(
      dataResetRepository: LiveRepositories.dataReset,
      settingsRepository: LiveRepositories.settings,
      authenticateUseCase: LiveUseCases.authenticate,
      expiryNotificationScheduler: LiveUseCases.expirySchedule
    )

    return DataSettingsClient(
      isICloudSyncEnabled: {
        useCase.isICloudSyncEnabled()
      },
      deleteAllData: {
        try await useCase.deleteAllData()
      }
    )
  }()
}
