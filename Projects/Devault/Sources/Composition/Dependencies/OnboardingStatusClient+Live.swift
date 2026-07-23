// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVPresentation
import DVDomain
import DVData

extension OnboardingStatusClient: @retroactive DependencyKey {
  public static let liveValue: OnboardingStatusClient = {
    let repository: any SettingsRepository = SettingsRepositoryImpl()
    let useCase: any OnboardingStatusUseCase = OnboardingStatusUseCaseImpl(repository: repository)

    return OnboardingStatusClient(
      hasCompleted: { useCase.hasCompleted() },
      setCompleted: { useCase.setCompleted() }
    )
  }()
}
