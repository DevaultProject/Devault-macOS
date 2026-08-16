// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVPresentation

extension AboutSettingsClient: @retroactive DependencyKey {
  public static let liveValue = AboutSettingsClient(
    appVersion: {
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }
  )
}
