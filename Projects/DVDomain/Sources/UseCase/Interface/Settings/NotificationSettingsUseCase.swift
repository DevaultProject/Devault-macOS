// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol NotificationSettingsUseCase: Sendable {
  func isExpiryAlertsEnabled() -> Bool
  func setExpiryAlertsEnabled(_ enabled: Bool)

  /// 만료 며칠 전에 알림을 보낼지(예: [30, 7, 1, 0], 0은 당일).
  func expiryAlertDaysBefore() -> [Int]
  func setExpiryAlertDaysBefore(_ days: [Int])

  func isAuthFailureAlertEnabled() -> Bool
  func setAuthFailureAlertEnabled(_ enabled: Bool)

  func isClipboardAbnormalAccessAlertEnabled() -> Bool
  func setClipboardAbnormalAccessAlertEnabled(_ enabled: Bool)
}
