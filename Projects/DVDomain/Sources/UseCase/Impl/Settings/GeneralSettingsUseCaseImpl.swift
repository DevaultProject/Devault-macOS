// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct GeneralSettingsUseCaseImpl: GeneralSettingsUseCase {

  private let repository: any SettingsRepository
  private let launchAtLoginService: any LaunchAtLoginService

  public init(
    repository: any SettingsRepository,
    launchAtLoginService: any LaunchAtLoginService
  ) {
    self.repository = repository
    self.launchAtLoginService = launchAtLoginService
  }

  public func isLaunchAtLoginEnabled() -> Bool {
    let isEnabled = launchAtLoginService.isEnabled()

    if repository.isLaunchAtLoginEnabled() != isEnabled {
      repository.setLaunchAtLoginEnabled(isEnabled)
    }

    return isEnabled
  }

  public func setLaunchAtLoginEnabled(_ enabled: Bool) throws {
    try launchAtLoginService.setEnabled(enabled)
    repository.setLaunchAtLoginEnabled(enabled)
  }

  public func defaultEnvironment() -> String {
    repository.defaultEnvironment()
  }

  public func setDefaultEnvironment(_ rawValue: String) {
    repository.setDefaultEnvironment(rawValue)
  }
}
