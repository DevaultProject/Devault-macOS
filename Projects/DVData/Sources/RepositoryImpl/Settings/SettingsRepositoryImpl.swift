// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVDomain

public struct SettingsRepositoryImpl: SettingsRepository, @unchecked Sendable {

  private let defaults: UserDefaults

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  public func hasCompletedOnboarding() -> Bool {
    defaults.bool(forKey: .hasCompletedOnboarding)
  }

  public func setOnboardingCompleted() {
    defaults.set(true, forKey: .hasCompletedOnboarding)
  }
}
