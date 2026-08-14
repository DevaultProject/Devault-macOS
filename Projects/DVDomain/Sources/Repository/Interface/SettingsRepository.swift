// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol SettingsRepository: Sendable {
  /// 온보딩을 완료했는지 확인한다.
  func hasCompletedOnboarding() -> Bool
  /// 온보딩 완료 상태를 저장한다.
  func setOnboardingCompleted()

  /// iCloud 동기화 사용 여부를 확인한다.
  func isICloudSyncEnabled() -> Bool
  /// iCloud 동기화 사용 여부를 저장한다.
  /// - Parameter enabled: 사용 여부
  func setICloudSyncEnabled(_ enabled: Bool)

  // MARK: - General

  /// 로그인 시 자동 실행 여부를 확인한다.
  func isLaunchAtLoginEnabled() -> Bool
  func setLaunchAtLoginEnabled(_ enabled: Bool)

  /// 새 Secret 생성 시 자동 적용되는 기본 환경(rawValue). 미설정이면 nil.
  func defaultEnvironment() -> String?
  func setDefaultEnvironment(_ rawValue: String?)

  // MARK: - Security

  /// 앱 실행 시 인증 요구 여부.
  func isRequireAuthOnLaunchEnabled() -> Bool
  func setRequireAuthOnLaunchEnabled(_ enabled: Bool)

  /// Secret 값 복사 시 인증 요구 여부.
  func isRequireAuthToCopyEnabled() -> Bool
  func setRequireAuthToCopyEnabled(_ enabled: Bool)

  /// 비활성 후 자동 잠금까지의 시간(분). 0이면 "사용 안 함".
  func autoLockMinutes() -> Int
  func setAutoLockMinutes(_ minutes: Int)

  /// 클립보드 자동 비우기 사용 여부.
  func isAutoClearClipboardEnabled() -> Bool
  func setAutoClearClipboardEnabled(_ enabled: Bool)

  /// 클립보드 자동 비우기까지의 시간(초).
  func autoClearClipboardDelaySeconds() -> Int
  func setAutoClearClipboardDelaySeconds(_ seconds: Int)

  /// 화면 녹화 중 값 숨김 여부.
  func isHideDuringScreenRecordingEnabled() -> Bool
  func setHideDuringScreenRecordingEnabled(_ enabled: Bool)

  // MARK: - Notifications

  /// 만료 알림 사용 여부.
  func isExpiryAlertsEnabled() -> Bool
  func setExpiryAlertsEnabled(_ enabled: Bool)

  /// 만료 며칠 전에 알림을 보낼지(예: [30, 7, 1, 0], 0은 당일).
  func expiryAlertDaysBefore() -> [Int]
  func setExpiryAlertDaysBefore(_ days: [Int])

  /// 반복 인증 실패 알림 사용 여부.
  func isAuthFailureAlertEnabled() -> Bool
  func setAuthFailureAlertEnabled(_ enabled: Bool)

  /// 클립보드 반복 복사(비정상 접근) 알림 사용 여부.
  func isClipboardAbnormalAccessAlertEnabled() -> Bool
  func setClipboardAbnormalAccessAlertEnabled(_ enabled: Bool)
}
