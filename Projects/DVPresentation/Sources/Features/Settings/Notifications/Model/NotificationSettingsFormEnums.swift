// Copyright © 2026 Devault. All rights reserved

import Foundation
import DVDomain

extension ExpiryAlertDay {
  var displayName: LocalizedStringResource {
    switch self {
    case .thirtyDaysBefore:
      return .module("30 days before expiration")
    case .sevenDaysBefore:
      return .module("7 days before expiration")
    case .threeDaysBefore:
      return .module("3 days before expiration")
    case .expirationDay:
      return .module("On the day of expiration")
    }
  }
}
