// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol SecuritySettingsUseCase: Sendable {
  func isRequireAuthOnLaunchEnabled() -> Bool
  func setRequireAuthOnLaunchEnabled(_ enabled: Bool)

  func isRequireAuthToCopyEnabled() -> Bool
  func setRequireAuthToCopyEnabled(_ enabled: Bool)

  func isAutoLockEnabled() -> Bool
  func setAutoLockEnabled(_ enabled: Bool)

  /// 비활성 후 자동 잠금까지의 시간(분).
  func autoLockMinutes() -> Int
  func setAutoLockMinutes(_ minutes: Int)

  func isAutoClearClipboardEnabled() -> Bool
  func setAutoClearClipboardEnabled(_ enabled: Bool)

  func autoClearClipboardDelaySeconds() -> Int
  func setAutoClearClipboardDelaySeconds(_ seconds: Int)

  func isHideDuringScreenRecordingEnabled() -> Bool
  func setHideDuringScreenRecordingEnabled(_ enabled: Bool)

  /// 구독을 시작하면 현재 설정값을 즉시 한 번 방출하고, 이후 설정이 변경될 때마다 최신값을 방출한다.
  func hideDuringScreenRecordingEnabledStream() -> AsyncStream<Bool>
}
