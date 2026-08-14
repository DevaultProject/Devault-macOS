// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

/// Settings 화면 전용 Client. 카테고리별로 메서드를 늘려간다.
@DependencyClient
public struct SettingsClient: Sendable {

  // MARK: - General

  public var isLaunchAtLoginEnabled: @Sendable () -> Bool = { false }
  /// 로그인 항목 등록/해제(SMAppService)까지 수행한 뒤 설정을 저장한다. 실패하면 저장하지 않는다.
  public var setLaunchAtLoginEnabled: @Sendable (Bool) throws -> Void

  public var defaultEnvironment: @Sendable () -> String? = { nil }
  public var setDefaultEnvironment: @Sendable (String?) -> Void

  // MARK: - Security

  public var isRequireAuthOnLaunchEnabled: @Sendable () -> Bool = { true }
  public var setRequireAuthOnLaunchEnabled: @Sendable (Bool) -> Void

  public var isRequireAuthToCopyEnabled: @Sendable () -> Bool = { true }
  public var setRequireAuthToCopyEnabled: @Sendable (Bool) -> Void

  /// 비활성 후 자동 잠금까지의 시간(분). 0이면 "사용 안 함".
  public var autoLockMinutes: @Sendable () -> Int = { 5 }
  public var setAutoLockMinutes: @Sendable (Int) -> Void

  public var isAutoClearClipboardEnabled: @Sendable () -> Bool = { true }
  public var setAutoClearClipboardEnabled: @Sendable (Bool) -> Void

  public var autoClearClipboardDelaySeconds: @Sendable () -> Int = { 30 }
  public var setAutoClearClipboardDelaySeconds: @Sendable (Int) -> Void

  public var isHideDuringScreenRecordingEnabled: @Sendable () -> Bool = { true }
  public var setHideDuringScreenRecordingEnabled: @Sendable (Bool) -> Void

  // MARK: - iCloud

  public var isICloudSyncEnabled: @Sendable () -> Bool = { false }
  public var setICloudSyncEnabled: @Sendable (Bool) -> Void
  public var openICloudSystemSettings: @Sendable () -> Void

  // MARK: - Notifications

  public var isExpiryAlertsEnabled: @Sendable () -> Bool = { true }
  public var setExpiryAlertsEnabled: @Sendable (Bool) -> Void

  /// 만료 며칠 전에 알림을 보낼지(예: [30, 7, 1, 0], 0은 당일).
  public var expiryAlertDaysBefore: @Sendable () -> [Int] = { [30, 7, 1, 0] }
  public var setExpiryAlertDaysBefore: @Sendable ([Int]) -> Void

  public var isAuthFailureAlertEnabled: @Sendable () -> Bool = { true }
  public var setAuthFailureAlertEnabled: @Sendable (Bool) -> Void

  public var isClipboardAbnormalAccessAlertEnabled: @Sendable () -> Bool = { true }
  public var setClipboardAbnormalAccessAlertEnabled: @Sendable (Bool) -> Void

  /// macOS 알림 권한이 허용돼 있는지. 꺼져 있으면 위 설정을 켜도 실제로는 알림이 안 온다.
  public var isNotificationPermissionGranted: @Sendable () async -> Bool = { true }
  public var openNotificationSystemSettings: @Sendable () -> Void
}

extension SettingsClient: TestDependencyKey {
  public static let testValue = SettingsClient()

  public static let previewValue = SettingsClient(
    isLaunchAtLoginEnabled: { false },
    setLaunchAtLoginEnabled: { _ in },
    defaultEnvironment: { nil },
    setDefaultEnvironment: { _ in },
    isRequireAuthOnLaunchEnabled: { true },
    setRequireAuthOnLaunchEnabled: { _ in },
    isRequireAuthToCopyEnabled: { true },
    setRequireAuthToCopyEnabled: { _ in },
    autoLockMinutes: { 5 },
    setAutoLockMinutes: { _ in },
    isAutoClearClipboardEnabled: { true },
    setAutoClearClipboardEnabled: { _ in },
    autoClearClipboardDelaySeconds: { 30 },
    setAutoClearClipboardDelaySeconds: { _ in },
    isHideDuringScreenRecordingEnabled: { true },
    setHideDuringScreenRecordingEnabled: { _ in },
    isICloudSyncEnabled: { false },
    setICloudSyncEnabled: { _ in },
    openICloudSystemSettings: { },
    isExpiryAlertsEnabled: { true },
    setExpiryAlertsEnabled: { _ in },
    expiryAlertDaysBefore: { [30, 7, 1, 0] },
    setExpiryAlertDaysBefore: { _ in },
    isAuthFailureAlertEnabled: { true },
    setAuthFailureAlertEnabled: { _ in },
    isClipboardAbnormalAccessAlertEnabled: { true },
    setClipboardAbnormalAccessAlertEnabled: { _ in },
    isNotificationPermissionGranted: { true },
    openNotificationSystemSettings: { }
  )
}

extension DependencyValues {
  public var settingsClient: SettingsClient {
    get { self[SettingsClient.self] }
    set { self[SettingsClient.self] = newValue }
  }
}
