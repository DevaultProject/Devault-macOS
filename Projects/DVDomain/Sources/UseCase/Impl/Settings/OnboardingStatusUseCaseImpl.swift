// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct OnboardingStatusUseCaseImpl: OnboardingStatusUseCase {

  private let repository: any SettingsRepository

  public init(repository: any SettingsRepository) {
    self.repository = repository
  }

  public func hasCompleted() -> Bool {
    repository.hasCompletedOnboarding()
  }

  public func setCompleted() {
    repository.setOnboardingCompleted()
  }
}
