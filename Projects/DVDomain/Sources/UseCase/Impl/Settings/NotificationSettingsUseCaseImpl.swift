// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct NotificationSettingsUseCaseImpl: NotificationSettingsUseCase {

  private let repository: any SettingsRepository

  public init(repository: any SettingsRepository) {
    self.repository = repository
  }

  public func isExpiryAlertsEnabled() -> Bool {
    repository.isExpiryAlertsEnabled()
  }

  public func setExpiryAlertsEnabled(_ enabled: Bool) {
    repository.setExpiryAlertsEnabled(enabled)
  }

  public func expiryAlertDaysBefore() -> [Int] {
    repository.expiryAlertDaysBefore()
  }

  public func setExpiryAlertDaysBefore(_ days: [Int]) {
    repository.setExpiryAlertDaysBefore(days)
  }

  public func isAuthFailureAlertEnabled() -> Bool {
    repository.isAuthFailureAlertEnabled()
  }

  public func setAuthFailureAlertEnabled(_ enabled: Bool) {
    repository.setAuthFailureAlertEnabled(enabled)
  }

  public func isClipboardAbnormalAccessAlertEnabled() -> Bool {
    repository.isClipboardAbnormalAccessAlertEnabled()
  }

  public func setClipboardAbnormalAccessAlertEnabled(_ enabled: Bool) {
    repository.setClipboardAbnormalAccessAlertEnabled(enabled)
  }
}
