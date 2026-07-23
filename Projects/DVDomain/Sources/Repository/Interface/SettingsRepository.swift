// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol SettingsRepository: Sendable {
  func hasCompletedOnboarding() -> Bool
  func setOnboardingCompleted()
}
