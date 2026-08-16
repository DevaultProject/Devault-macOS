// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain

@DependencyClient
public struct NotificationSettingsClient: Sendable {
  public var isExpiryAlertsEnabled: @Sendable () -> Bool = { true }
  public var setExpiryAlertsEnabled: @Sendable (Bool) async throws -> Void

  public var expiryAlertDaysBefore: @Sendable () -> [ExpiryAlertDay] = {
    ExpiryAlertDay.defaultSelection
  }
  public var setExpiryAlertDaysBefore: @Sendable ([ExpiryAlertDay]) async throws -> Void

  public var isAuthFailureAlertEnabled: @Sendable () -> Bool = { true }
  public var setAuthFailureAlertEnabled: @Sendable (Bool) -> Void

  public var isClipboardAbnormalAccessAlertEnabled: @Sendable () -> Bool = { true }
  public var setClipboardAbnormalAccessAlertEnabled: @Sendable (Bool) -> Void

  /// macOS 알림 권한이 허용돼 있는지. 꺼져 있으면 위 설정을 켜도 실제로는 알림이 안 온다.
  public var isPermissionGranted: @Sendable () async -> Bool = { true }
  public var openSystemSettings: @Sendable () -> Void
}

extension NotificationSettingsClient: TestDependencyKey {
  public static let testValue = NotificationSettingsClient()

  public static let previewValue = NotificationSettingsClient(
    isExpiryAlertsEnabled: { true },
    setExpiryAlertsEnabled: { _ in },
    expiryAlertDaysBefore: { ExpiryAlertDay.defaultSelection },
    setExpiryAlertDaysBefore: { _ in },
    isAuthFailureAlertEnabled: { true },
    setAuthFailureAlertEnabled: { _ in },
    isClipboardAbnormalAccessAlertEnabled: { true },
    setClipboardAbnormalAccessAlertEnabled: { _ in },
    isPermissionGranted: { true },
    openSystemSettings: { }
  )
}

extension DependencyValues {
  public var notificationSettingsClient: NotificationSettingsClient {
    get { self[NotificationSettingsClient.self] }
    set { self[NotificationSettingsClient.self] = newValue }
  }
}
