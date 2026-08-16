// Copyright © 2026 Devault. All rights reserved

public protocol LaunchAtLoginService: Sendable {
  func isEnabled() -> Bool
  func setEnabled(_ enabled: Bool) throws
}
