// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol ICloudSyncSettingsUseCase: Sendable {
  func isEnabled() -> Bool
  func setEnabled(_ enabled: Bool)
}
