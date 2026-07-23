// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol OnboardingStatusUseCase: Sendable {
  func hasCompleted() -> Bool
  func setCompleted()
}
