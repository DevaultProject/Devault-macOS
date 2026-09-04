// Copyright © 2026 Devault. All rights reserved

// MARK: - SettingsCategory

public enum SettingsCategory: String, Equatable, CaseIterable, Hashable, Sendable {
  case devaultPro
  case general
  case security
  case icloud
  case notifications
  case shortcuts
  case data
  case about

  /// 브랜드명이라 다른 탭과 달리 `.module(...)`로 번역하지 않는다.
  var title: String {
    switch self {
    case .devaultPro:    "DeVault Pro"
    case .general:       .module("General")
    case .security:      .module("Security")
    case .icloud:        .module("iCloud")
    case .notifications: .module("Notifications")
    case .shortcuts:     .module("Shortcuts")
    case .data:          .module("Data")
    case .about:         .module("About")
    }
  }

  var icon: String {
    switch self {
    case .devaultPro:    "crown"
    case .general:       "gearshape"
    case .security:      "lock.shield"
    case .icloud:        "icloud"
    case .notifications: "bell"
    case .shortcuts:     "keyboard"
    case .data:          "externaldrive"
    case .about:         "info.circle"
    }
  }
}
