// Copyright © 2026 Devault. All rights reserved

import Foundation
import DVDomain

// UserDefaults는 thread-safe하므로 @unchecked Sendable 허용
public struct SettingsRepositoryImpl: SettingsRepository, @unchecked Sendable {

  private let defaults: UserDefaults
  private let ubiquitousStore: NSUbiquitousKeyValueStore

  // TODO: SecretEnvironment를 DVDomain 공용 타입으로 이동하면 `.dev.rawValue`로 대체한다.
  private enum DefaultValue {
    static let environment = "dev"
  }

  public init(
    defaults: UserDefaults = .standard,
    ubiquitousStore: NSUbiquitousKeyValueStore = .default
  ) {
    self.defaults = defaults
    self.ubiquitousStore = ubiquitousStore

    // 아직 사용자가 저장한 값이 없을 때 사용할 기본값
    defaults.register(defaults: [
      UserDefaultsKey.defaultEnvironment.rawValue: DefaultValue.environment,
      UserDefaultsKey.isRequireAuthOnLaunchEnabled.rawValue: true,
      UserDefaultsKey.isRequireAuthToCopyEnabled.rawValue: true,
      UserDefaultsKey.isAutoLockEnabled.rawValue: true,
      UserDefaultsKey.autoLockMinutes.rawValue: 5,
      UserDefaultsKey.isAutoClearClipboardEnabled.rawValue: true,
      UserDefaultsKey.autoClearClipboardDelaySeconds.rawValue: 30,
      UserDefaultsKey.isHideDuringScreenRecordingEnabled.rawValue: true,
      UserDefaultsKey.isExpiryAlertsEnabled.rawValue: true,
      UserDefaultsKey.expiryAlertDaysBefore.rawValue: [30, 7, 1, 0],
      UserDefaultsKey.isAuthFailureAlertEnabled.rawValue: true,
      UserDefaultsKey.isClipboardAbnormalAccessAlertEnabled.rawValue: true,
    ])
  }

  // MARK: - Onboarding

  // hasCompletedOnboarding은 기기별로 Touch ID 확인이 필요하므로 로컬 UserDefaults로 관리
  public func hasCompletedOnboarding() -> Bool {
    defaults.bool(forKey: .hasCompletedOnboarding)
  }

  public func setOnboardingCompleted() {
    defaults.set(true, forKey: .hasCompletedOnboarding)
  }

  // MARK: - iCloud

  // iCloud 동기화 사용 여부는 독립적으로 켜야 하므로 로컬 UserDefaults로 관리
  public func isICloudSyncEnabled() -> Bool {
    defaults.bool(forKey: .isICloudSyncEnabled)
  }

  public func setICloudSyncEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: .isICloudSyncEnabled)
  }

  public func iCloudLastUpdateDetectedAt() -> Date? {
    defaults.date(forKey: .iCloudLastUpdateDetectedAt)
  }

  public func setICloudLastUpdateDetectedAt(_ date: Date) {
    defaults.set(date, forKey: .iCloudLastUpdateDetectedAt)
  }

  // MARK: - General

  public func isLaunchAtLoginEnabled() -> Bool {
    defaults.bool(forKey: .isLaunchAtLoginEnabled)
  }

  public func setLaunchAtLoginEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: .isLaunchAtLoginEnabled)
  }

  public func defaultEnvironment() -> String {
    defaults.string(forKey: .defaultEnvironment) ?? DefaultValue.environment
  }

  public func setDefaultEnvironment(_ rawValue: String) {
    defaults.set(rawValue, forKey: .defaultEnvironment)
  }

  // MARK: - Security

  public func isRequireAuthOnLaunchEnabled() -> Bool {
    defaults.bool(forKey: .isRequireAuthOnLaunchEnabled)
  }

  public func setRequireAuthOnLaunchEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: .isRequireAuthOnLaunchEnabled)
  }

  public func isRequireAuthToCopyEnabled() -> Bool {
    defaults.bool(forKey: .isRequireAuthToCopyEnabled)
  }

  public func setRequireAuthToCopyEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: .isRequireAuthToCopyEnabled)
  }

  public func isAutoLockEnabled() -> Bool {
    defaults.bool(forKey: .isAutoLockEnabled)
  }

  public func setAutoLockEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: .isAutoLockEnabled)
  }

  public func autoLockMinutes() -> Int {
    defaults.integer(forKey: .autoLockMinutes)
  }

  public func setAutoLockMinutes(_ minutes: Int) {
    defaults.set(minutes, forKey: .autoLockMinutes)
  }

  public func isAutoClearClipboardEnabled() -> Bool {
    defaults.bool(forKey: .isAutoClearClipboardEnabled)
  }

  public func setAutoClearClipboardEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: .isAutoClearClipboardEnabled)
  }

  public func autoClearClipboardDelaySeconds() -> Int {
    defaults.integer(forKey: .autoClearClipboardDelaySeconds)
  }

  public func setAutoClearClipboardDelaySeconds(_ seconds: Int) {
    defaults.set(seconds, forKey: .autoClearClipboardDelaySeconds)
  }

  public func isHideDuringScreenRecordingEnabled() -> Bool {
    defaults.bool(forKey: .isHideDuringScreenRecordingEnabled)
  }

  public func setHideDuringScreenRecordingEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: .isHideDuringScreenRecordingEnabled)
  }

  public func hideDuringScreenRecordingEnabledStream() -> AsyncStream<Bool> {
    AsyncStream { continuation in
      let observer = NotificationCenter.default.addObserver(
        forName: UserDefaults.didChangeNotification,
        object: defaults,
        queue: nil
      ) { _ in
        continuation.yield(isHideDuringScreenRecordingEnabled())
      }

      continuation.yield(isHideDuringScreenRecordingEnabled())
      continuation.onTermination = { _ in
        NotificationCenter.default.removeObserver(observer)
      }
    }
  }

  // MARK: - Notifications

  public func isExpiryAlertsEnabled() -> Bool {
    defaults.bool(forKey: .isExpiryAlertsEnabled)
  }

  public func setExpiryAlertsEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: .isExpiryAlertsEnabled)
  }

  public func expiryAlertDaysBefore() -> [Int] {
    defaults.integerArray(forKey: .expiryAlertDaysBefore) ?? [30, 7, 1, 0]
  }

  public func setExpiryAlertDaysBefore(_ days: [Int]) {
    defaults.set(days, forKey: .expiryAlertDaysBefore)
  }

  public func isAuthFailureAlertEnabled() -> Bool {
    defaults.bool(forKey: .isAuthFailureAlertEnabled)
  }

  public func setAuthFailureAlertEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: .isAuthFailureAlertEnabled)
  }

  public func isClipboardAbnormalAccessAlertEnabled() -> Bool {
    defaults.bool(forKey: .isClipboardAbnormalAccessAlertEnabled)
  }

  public func setClipboardAbnormalAccessAlertEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: .isClipboardAbnormalAccessAlertEnabled)
  }
}
