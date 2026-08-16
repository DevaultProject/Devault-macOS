// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct NotificationSettingsUseCaseImpl: NotificationSettingsUseCase {

  private let repository: any SettingsRepository
  private let expiryNotificationScheduler: any ScheduleSecretExpiryNotificationsUseCase

  public init(
    repository: any SettingsRepository,
    expiryNotificationScheduler: any ScheduleSecretExpiryNotificationsUseCase
  ) {
    self.repository = repository
    self.expiryNotificationScheduler = expiryNotificationScheduler
  }

  public func isExpiryAlertsEnabled() -> Bool {
    repository.isExpiryAlertsEnabled()
  }

  public func setExpiryAlertsEnabled(_ enabled: Bool) async throws {
    repository.setExpiryAlertsEnabled(enabled)
    try await expiryNotificationScheduler.syncAll()
  }

  public func expiryAlertDaysBefore() -> [Int] {
    repository.expiryAlertDaysBefore()
  }

  public func setExpiryAlertDaysBefore(_ days: [Int]) async throws {
    repository.setExpiryAlertDaysBefore(days)
    try await expiryNotificationScheduler.syncAll()
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
