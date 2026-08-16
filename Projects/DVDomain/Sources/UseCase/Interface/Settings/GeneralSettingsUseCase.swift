// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol GeneralSettingsUseCase: Sendable {
  func isLaunchAtLoginEnabled() -> Bool
  func setLaunchAtLoginEnabled(_ enabled: Bool) throws

  func defaultEnvironment() -> String
  func setDefaultEnvironment(_ rawValue: String)
}
