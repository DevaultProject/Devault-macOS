// Copyright © 2026 Devault. All rights reserved

import ServiceManagement

import DVDomain

public struct LaunchAtLoginServiceImpl: LaunchAtLoginService {

  public init() {}

  public func isEnabled() -> Bool {
    SMAppService.mainApp.status == .enabled
  }

  public func setEnabled(_ enabled: Bool) throws {
    if enabled {
      try SMAppService.mainApp.register()
    } else {
      try SMAppService.mainApp.unregister()
    }
  }
}
