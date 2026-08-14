// Copyright © 2026 Devault. All rights reserved

import Foundation

@testable import DVDomain

/// 테스트용 SettingsRepository 구현. UserDefaults 없이 메모리에만 저장한다.
public final class FakeSettingsRepository: SettingsRepository, @unchecked Sendable {
    public var hasCompletedOnboardingValue = false
    public var isICloudSyncEnabledValue = false
    public var iCloudLastSyncedAtValue: Date?

    public var isLaunchAtLoginEnabledValue = false
    public var defaultEnvironmentValue: String?

    public var isRequireAuthOnLaunchEnabledValue = true
    public var isRequireAuthToCopyEnabledValue = true
    public var autoLockMinutesValue = 5
    public var isAutoClearClipboardEnabledValue = true
    public var autoClearClipboardDelaySecondsValue = 30
    public var isHideDuringScreenRecordingEnabledValue = true

    public var isExpiryAlertsEnabledValue = true
    public var expiryAlertDaysBeforeValue = [30, 7, 1, 0]
    public var isAuthFailureAlertEnabledValue = true
    public var isClipboardAbnormalAccessAlertEnabledValue = true

    public init() {}

    public func hasCompletedOnboarding() -> Bool { hasCompletedOnboardingValue }
    public func setOnboardingCompleted() { hasCompletedOnboardingValue = true }

    public func isICloudSyncEnabled() -> Bool { isICloudSyncEnabledValue }
    public func setICloudSyncEnabled(_ enabled: Bool) { isICloudSyncEnabledValue = enabled }

    public func iCloudLastSyncedAt() -> Date? { iCloudLastSyncedAtValue }
    public func setICloudLastSyncedAt(_ date: Date) { iCloudLastSyncedAtValue = date }

    public func isLaunchAtLoginEnabled() -> Bool { isLaunchAtLoginEnabledValue }
    public func setLaunchAtLoginEnabled(_ enabled: Bool) { isLaunchAtLoginEnabledValue = enabled }

    public func defaultEnvironment() -> String? { defaultEnvironmentValue }
    public func setDefaultEnvironment(_ rawValue: String?) { defaultEnvironmentValue = rawValue }

    public func isRequireAuthOnLaunchEnabled() -> Bool { isRequireAuthOnLaunchEnabledValue }
    public func setRequireAuthOnLaunchEnabled(_ enabled: Bool) { isRequireAuthOnLaunchEnabledValue = enabled }

    public func isRequireAuthToCopyEnabled() -> Bool { isRequireAuthToCopyEnabledValue }
    public func setRequireAuthToCopyEnabled(_ enabled: Bool) { isRequireAuthToCopyEnabledValue = enabled }

    public func autoLockMinutes() -> Int { autoLockMinutesValue }
    public func setAutoLockMinutes(_ minutes: Int) { autoLockMinutesValue = minutes }

    public func isAutoClearClipboardEnabled() -> Bool { isAutoClearClipboardEnabledValue }
    public func setAutoClearClipboardEnabled(_ enabled: Bool) { isAutoClearClipboardEnabledValue = enabled }

    public func autoClearClipboardDelaySeconds() -> Int { autoClearClipboardDelaySecondsValue }
    public func setAutoClearClipboardDelaySeconds(_ seconds: Int) { autoClearClipboardDelaySecondsValue = seconds }

    public func isHideDuringScreenRecordingEnabled() -> Bool { isHideDuringScreenRecordingEnabledValue }
    public func setHideDuringScreenRecordingEnabled(_ enabled: Bool) { isHideDuringScreenRecordingEnabledValue = enabled }

    public func isExpiryAlertsEnabled() -> Bool { isExpiryAlertsEnabledValue }
    public func setExpiryAlertsEnabled(_ enabled: Bool) { isExpiryAlertsEnabledValue = enabled }

    public func expiryAlertDaysBefore() -> [Int] { expiryAlertDaysBeforeValue }
    public func setExpiryAlertDaysBefore(_ days: [Int]) { expiryAlertDaysBeforeValue = days }

    public func isAuthFailureAlertEnabled() -> Bool { isAuthFailureAlertEnabledValue }
    public func setAuthFailureAlertEnabled(_ enabled: Bool) { isAuthFailureAlertEnabledValue = enabled }

    public func isClipboardAbnormalAccessAlertEnabled() -> Bool { isClipboardAbnormalAccessAlertEnabledValue }
    public func setClipboardAbnormalAccessAlertEnabled(_ enabled: Bool) { isClipboardAbnormalAccessAlertEnabledValue = enabled }
}
