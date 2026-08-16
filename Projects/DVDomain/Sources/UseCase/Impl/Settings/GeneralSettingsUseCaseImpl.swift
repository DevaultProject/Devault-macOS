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

  public func launchAtLoginStatus() -> LaunchAtLoginStatus {
    let status = launchAtLoginService.status()
    let isRegistered = status.isRegistered

    if repository.isLaunchAtLoginEnabled() != isRegistered {
      repository.setLaunchAtLoginEnabled(isRegistered)
    }

    return status
  }

  public func setLaunchAtLoginEnabled(_ enabled: Bool) throws -> LaunchAtLoginStatus {
    let status = try launchAtLoginService.setEnabled(enabled)
    repository.setLaunchAtLoginEnabled(status.isRegistered)
    return status
  }

  public func openLoginItemsSystemSettings() {
    launchAtLoginService.openSystemSettings()
  }

  public func defaultEnvironment() -> String {
    repository.defaultEnvironment()
  }

  public func setDefaultEnvironment(_ rawValue: String) {
    repository.setDefaultEnvironment(rawValue)
  }
}
