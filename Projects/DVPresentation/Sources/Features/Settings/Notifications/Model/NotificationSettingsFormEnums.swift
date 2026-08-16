// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 만료 알림 시점을 표현하는 Presentation VO.
public enum ExpiryAlertDay: Int, CaseIterable, Hashable, Identifiable {
  case thirtyDaysBefore = 30
  case sevenDaysBefore = 7
  case oneDayBefore = 1
  case expirationDay = 0

  public var id: Int { rawValue }

  var displayName: LocalizedStringResource {
    switch self {
    case .thirtyDaysBefore:
      return .module("30 days before expiration")
    case .sevenDaysBefore:
      return .module("7 days before expiration")
    case .oneDayBefore:
      return .module("1 day before expiration")
    case .expirationDay:
      return .module("On the day of expiration")
    }
  }
}
