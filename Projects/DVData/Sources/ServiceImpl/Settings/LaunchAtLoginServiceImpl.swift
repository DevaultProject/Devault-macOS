// Copyright © 2026 Devault. All rights reserved

import ServiceManagement

import DVDomain

public struct LaunchAtLoginServiceImpl: LaunchAtLoginService {

  public init() {}

  public func status() -> LaunchAtLoginStatus {
    switch SMAppService.mainApp.status {
    case .notRegistered:
      .notRegistered
    case .enabled:
      .enabled
    case .requiresApproval:
      .requiresApproval
    case .notFound:
      .notFound
    @unknown default:
      .notFound
    }
  }

  public func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginStatus {
    if enabled {
      try SMAppService.mainApp.register()
    } else {
      try SMAppService.mainApp.unregister()
    }
    return status()
  }

  public func openSystemSettings() {
    SMAppService.openSystemSettingsLoginItems()
  }
}
