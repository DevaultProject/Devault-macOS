// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct NotificationSettingsUseCaseImpl: NotificationSettingsUseCase {

  private let repository: any SettingsRepository
  private let expiryNotificationScheduler: any ScheduleSecretExpiryNotificationsUseCase
  private let entitlementUseCase: any EntitlementUseCase

  /// - Parameters:
  ///   - repository: 설정 저장소
  ///   - expiryNotificationScheduler: 설정 변경 후 예약 동기화
  ///   - entitlementUseCase: 다중 시점 사용 가능 여부 판정. **기본값을 두지 않는다** — 빠뜨리면 가드가 조용히 사라진다
  public init(
    repository: any SettingsRepository,
    expiryNotificationScheduler: any ScheduleSecretExpiryNotificationsUseCase,
    entitlementUseCase: any EntitlementUseCase
  ) {
    self.repository = repository
    self.expiryNotificationScheduler = expiryNotificationScheduler
    self.entitlementUseCase = entitlementUseCase
  }

  public func isExpiryAlertsEnabled() -> Bool {
    repository.isExpiryAlertsEnabled()
  }

  public func setExpiryAlertsEnabled(_ enabled: Bool) async throws {
    repository.setExpiryAlertsEnabled(enabled)
    try await expiryNotificationScheduler.syncAll()
  }

  public func expiryAlertDaysBefore() -> [ExpiryAlertDay] {
    repository.expiryAlertDaysBefore()
  }

  public func setExpiryAlertDaysBefore(_ days: [ExpiryAlertDay]) async throws {
    // 이미 저장된 값은 건드리지 않는다(설계 §2). 여기서 막는 것은 **새로 여러 개를 고르는 것**뿐이다.
    if days.count > EntitlementLimits.maxExpiryAlertDays,
       !entitlementUseCase.canUseMultipleExpiryAlertDays() {
      throw EntitlementError.requiresPro
    }
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
