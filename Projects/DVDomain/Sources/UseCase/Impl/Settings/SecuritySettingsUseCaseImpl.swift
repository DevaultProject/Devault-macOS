// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct SecuritySettingsUseCaseImpl: SecuritySettingsUseCase {

  private let repository: any SettingsRepository

  public init(repository: any SettingsRepository) {
    self.repository = repository
  }

  public func isRequireAuthOnLaunchEnabled() -> Bool {
    repository.isRequireAuthOnLaunchEnabled()
  }

  public func setRequireAuthOnLaunchEnabled(_ enabled: Bool) {
    repository.setRequireAuthOnLaunchEnabled(enabled)
  }

  public func isRequireAuthToCopyEnabled() -> Bool {
    repository.isRequireAuthToCopyEnabled()
  }

  public func setRequireAuthToCopyEnabled(_ enabled: Bool) {
    repository.setRequireAuthToCopyEnabled(enabled)
  }

  public func isAutoLockEnabled() -> Bool {
    repository.isAutoLockEnabled()
  }

  public func setAutoLockEnabled(_ enabled: Bool) {
    repository.setAutoLockEnabled(enabled)
  }

  public func autoLockMinutes() -> Int {
    repository.autoLockMinutes()
  }

  public func setAutoLockMinutes(_ minutes: Int) {
    repository.setAutoLockMinutes(minutes)
  }

  public func isAutoClearClipboardEnabled() -> Bool {
    repository.isAutoClearClipboardEnabled()
  }

  public func setAutoClearClipboardEnabled(_ enabled: Bool) {
    repository.setAutoClearClipboardEnabled(enabled)
  }

  public func autoClearClipboardDelaySeconds() -> Int {
    repository.autoClearClipboardDelaySeconds()
  }

  public func setAutoClearClipboardDelaySeconds(_ seconds: Int) {
    repository.setAutoClearClipboardDelaySeconds(seconds)
  }

  public func isWindowCaptureProtectionEnabled() -> Bool {
    repository.isWindowCaptureProtectionEnabled()
  }

  public func setWindowCaptureProtectionEnabled(_ enabled: Bool) {
    repository.setWindowCaptureProtectionEnabled(enabled)
  }

  public func windowCaptureProtectionEnabledStream() -> AsyncStream<Bool> {
    repository.windowCaptureProtectionEnabledStream()
  }
}
