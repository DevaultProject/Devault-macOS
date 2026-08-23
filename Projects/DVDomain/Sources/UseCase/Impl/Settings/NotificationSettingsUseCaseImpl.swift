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
    // 여기서 막는 것은 **늘리는 것**뿐이다. 줄이는 저장은 통과시켜야 한다 — Pro에서 내려온 사용자가
    // 3개를 보유한 채 하나를 빼려 하면 결과가 2개라 한도를 넘지만, 그건 한도로 다가가는 정상 동작이다.
    // 막으면 저장이 실패해 UI와 저장소가 어긋난 채 빠져나갈 길이 없어진다.
    let previous = repository.expiryAlertDaysBefore().count
    if days.count > EntitlementLimits.maxExpiryAlertDays,
       days.count > previous,
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
