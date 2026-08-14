// Copyright © 2026 Devault. All rights reserved

// MARK: - SettingsCategory

enum SettingsCategory: String, Equatable, CaseIterable, Hashable, Sendable {
  case general
  case security
  case icloud
  case notifications
  case shortcuts
  case data
  case about

  var title: String {
    switch self {
    case .general:       .module("General")
    case .security:      .module("Security")
    case .icloud:         .module("iCloud")
    case .notifications: .module("Notifications")
    case .shortcuts:     .module("Shortcuts")
    case .data:          .module("Data")
    case .about:         .module("About")
    }
  }

  var icon: String {
    switch self {
    case .general:       "gearshape"
    case .security:      "lock.shield"
    case .icloud:         "icloud"
    case .notifications: "bell"
    case .shortcuts:     "keyboard"
    case .data:          "externaldrive"
    case .about:         "info.circle"
    }
  }
}
