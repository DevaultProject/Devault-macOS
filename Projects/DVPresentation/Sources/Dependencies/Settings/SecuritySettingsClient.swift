// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

@DependencyClient
public struct SecuritySettingsClient: Sendable {
  public var isRequireAuthOnLaunchEnabled: @Sendable () -> Bool = { true }
  public var setRequireAuthOnLaunchEnabled: @Sendable (Bool) -> Void

  public var isRequireAuthToCopyEnabled: @Sendable () -> Bool = { true }
  public var setRequireAuthToCopyEnabled: @Sendable (Bool) -> Void

  public var isAutoLockEnabled: @Sendable () -> Bool = { true }
  public var setAutoLockEnabled: @Sendable (Bool) -> Void

  /// 비활성 후 자동 잠금까지의 시간(분).
  public var autoLockMinutes: @Sendable () -> Int = { 5 }
  public var setAutoLockMinutes: @Sendable (Int) -> Void

  public var isAutoClearClipboardEnabled: @Sendable () -> Bool = { true }
  public var setAutoClearClipboardEnabled: @Sendable (Bool) -> Void

  public var autoClearClipboardDelaySeconds: @Sendable () -> Int = { 30 }
  public var setAutoClearClipboardDelaySeconds: @Sendable (Int) -> Void

  public var isHideDuringScreenRecordingEnabled: @Sendable () -> Bool = { true }
  public var setHideDuringScreenRecordingEnabled: @Sendable (Bool) -> Void
}

extension SecuritySettingsClient: TestDependencyKey {
  public static let testValue = SecuritySettingsClient()

  public static let previewValue = SecuritySettingsClient(
    isRequireAuthOnLaunchEnabled: { true },
    setRequireAuthOnLaunchEnabled: { _ in },
    isRequireAuthToCopyEnabled: { true },
    setRequireAuthToCopyEnabled: { _ in },
    isAutoLockEnabled: { true },
    setAutoLockEnabled: { _ in },
    autoLockMinutes: { 5 },
    setAutoLockMinutes: { _ in },
    isAutoClearClipboardEnabled: { true },
    setAutoClearClipboardEnabled: { _ in },
    autoClearClipboardDelaySeconds: { 30 },
    setAutoClearClipboardDelaySeconds: { _ in },
    isHideDuringScreenRecordingEnabled: { true },
    setHideDuringScreenRecordingEnabled: { _ in }
  )
}

extension DependencyValues {
  public var securitySettingsClient: SecuritySettingsClient {
    get { self[SecuritySettingsClient.self] }
    set { self[SecuritySettingsClient.self] = newValue }
  }
}
