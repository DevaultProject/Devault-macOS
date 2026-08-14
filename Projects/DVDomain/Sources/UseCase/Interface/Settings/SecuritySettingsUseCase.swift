// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol SecuritySettingsUseCase: Sendable {
  func isRequireAuthOnLaunchEnabled() -> Bool
  func setRequireAuthOnLaunchEnabled(_ enabled: Bool)

  func isRequireAuthToCopyEnabled() -> Bool
  func setRequireAuthToCopyEnabled(_ enabled: Bool)

  /// 비활성 후 자동 잠금까지의 시간(분). 0이면 "사용 안 함".
  func autoLockMinutes() -> Int
  func setAutoLockMinutes(_ minutes: Int)

  func isAutoClearClipboardEnabled() -> Bool
  func setAutoClearClipboardEnabled(_ enabled: Bool)

  func autoClearClipboardDelaySeconds() -> Int
  func setAutoClearClipboardDelaySeconds(_ seconds: Int)

  func isHideDuringScreenRecordingEnabled() -> Bool
  func setHideDuringScreenRecordingEnabled(_ enabled: Bool)
}
