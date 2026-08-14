// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct GeneralSettingsUseCaseImpl: GeneralSettingsUseCase {

  private let repository: any SettingsRepository

  public init(repository: any SettingsRepository) {
    self.repository = repository
  }

  public func isLaunchAtLoginEnabled() -> Bool {
    repository.isLaunchAtLoginEnabled()
  }

  public func setLaunchAtLoginEnabled(_ enabled: Bool) {
    repository.setLaunchAtLoginEnabled(enabled)
  }

  public func defaultEnvironment() -> String? {
    repository.defaultEnvironment()
  }

  public func setDefaultEnvironment(_ rawValue: String?) {
    repository.setDefaultEnvironment(rawValue)
  }
}
