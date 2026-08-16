// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol SettingsRepository: Sendable {
  // MARK: - Onboarding

  /// 온보딩을 완료했는지 확인한다.
  /// - Returns: 온보딩 완료 여부
  func hasCompletedOnboarding() -> Bool
  /// 온보딩 완료 상태를 저장한다.
  func setOnboardingCompleted()

  // MARK: - iCloud

  /// iCloud 동기화 사용 여부를 확인한다.
  /// - Returns: iCloud 동기화 사용 여부
  func isICloudSyncEnabled() -> Bool
  /// iCloud 동기화 사용 여부를 저장한다.
  /// - Parameter enabled: 사용 여부
  func setICloudSyncEnabled(_ enabled: Bool)

  /// 마지막으로 CloudKit 원격 변경이 감지된 시각. 한 번도 없었으면 nil.
  /// - Returns: 마지막 원격 변경 감지 시각. 기록이 없으면 nil
  func iCloudLastSyncedAt() -> Date?
  /// 마지막 CloudKit 원격 변경 감지 시각을 저장한다.
  /// - Parameter date: 저장할 원격 변경 감지 시각
  func setICloudLastSyncedAt(_ date: Date)

  // MARK: - General

  /// 로그인 시 자동 실행 여부를 확인한다.
  /// - Returns: 로그인 시 자동 실행 여부
  func isLaunchAtLoginEnabled() -> Bool
  /// 로그인 시 자동 실행 여부를 저장한다.
  /// - Parameter enabled: 로그인 시 자동 실행 여부
  func setLaunchAtLoginEnabled(_ enabled: Bool)

  /// 새 Secret 생성 시 자동 적용되는 기본 환경(rawValue).
  /// - Returns: 기본 환경의 rawValue
  func defaultEnvironment() -> String
  /// 새 Secret 생성 시 적용할 기본 환경(rawValue)을 저장한다.
  /// - Parameter rawValue: 저장할 기본 환경의 rawValue
  func setDefaultEnvironment(_ rawValue: String)

  // MARK: - Security

  /// 앱 실행 시 인증 요구 여부.
  /// - Returns: 앱 실행 시 인증 요구 여부
  func isRequireAuthOnLaunchEnabled() -> Bool
  /// 앱 실행 시 인증 요구 여부를 저장한다.
  /// - Parameter enabled: 앱 실행 시 인증 요구 여부
  func setRequireAuthOnLaunchEnabled(_ enabled: Bool)

  /// Secret 값 복사 시 인증 요구 여부.
  /// - Returns: Secret 값 복사 시 인증 요구 여부
  func isRequireAuthToCopyEnabled() -> Bool
  /// Secret 값 복사 시 인증 요구 여부를 저장한다.
  /// - Parameter enabled: Secret 값 복사 시 인증 요구 여부
  func setRequireAuthToCopyEnabled(_ enabled: Bool)

  /// 비활성 후 자동 잠금 사용 여부.
  /// - Returns: 자동 잠금 사용 여부
  func isAutoLockEnabled() -> Bool
  /// 비활성 후 자동 잠금 사용 여부를 저장한다.
  /// - Parameter enabled: 자동 잠금 사용 여부
  func setAutoLockEnabled(_ enabled: Bool)

  /// 비활성 후 자동 잠금까지의 시간(분).
  /// - Returns: 자동 잠금까지의 시간(분)
  func autoLockMinutes() -> Int
  /// 비활성 후 자동 잠금까지의 시간(분)을 저장한다.
  /// - Parameter minutes: 저장할 자동 잠금 시간(분)
  func setAutoLockMinutes(_ minutes: Int)

  /// 클립보드 자동 비우기 사용 여부.
  /// - Returns: 클립보드 자동 비우기 사용 여부
  func isAutoClearClipboardEnabled() -> Bool
  /// 클립보드 자동 비우기 사용 여부를 저장한다.
  /// - Parameter enabled: 클립보드 자동 비우기 사용 여부
  func setAutoClearClipboardEnabled(_ enabled: Bool)

  /// 클립보드 자동 비우기까지의 시간(초).
  /// - Returns: 클립보드 자동 비우기까지의 시간(초)
  func autoClearClipboardDelaySeconds() -> Int
  /// 클립보드 자동 비우기까지의 시간(초)을 저장한다.
  /// - Parameter seconds: 저장할 클립보드 자동 비우기 시간(초)
  func setAutoClearClipboardDelaySeconds(_ seconds: Int)

  /// 화면 녹화 중 값 숨김 여부.
  /// - Returns: 화면 녹화 중 값 숨김 여부
  func isHideDuringScreenRecordingEnabled() -> Bool
  /// 화면 녹화 중 값 숨김 여부를 저장한다.
  /// - Parameter enabled: 화면 녹화 중 값 숨김 여부
  func setHideDuringScreenRecordingEnabled(_ enabled: Bool)

  /// 구독을 시작하면 현재 설정값을 즉시 한 번 방출하고, 이후 설정이 변경될 때마다 최신값을 방출한다.
  /// - Returns: 화면 녹화 중 값 숨김 설정 스트림
  func hideDuringScreenRecordingEnabledStream() -> AsyncStream<Bool>

  // MARK: - Notifications

  /// 만료 알림 사용 여부.
  /// - Returns: 만료 알림 사용 여부
  func isExpiryAlertsEnabled() -> Bool
  /// 만료 알림 사용 여부를 저장한다.
  /// - Parameter enabled: 만료 알림 사용 여부
  func setExpiryAlertsEnabled(_ enabled: Bool)

  /// 만료 며칠 전에 알림을 보낼지(예: [30, 7, 1, 0], 0은 당일).
  /// - Returns: 만료 전 알림 발송 일수 목록
  func expiryAlertDaysBefore() -> [Int]
  /// 만료 알림을 보낼 만료 전 일수 목록을 저장한다.
  /// - Parameter days: 저장할 만료 전 알림 발송 일수 목록
  func setExpiryAlertDaysBefore(_ days: [Int])

  /// 반복 인증 실패 알림 사용 여부.
  /// - Returns: 반복 인증 실패 알림 사용 여부
  func isAuthFailureAlertEnabled() -> Bool
  /// 반복 인증 실패 알림 사용 여부를 저장한다.
  /// - Parameter enabled: 반복 인증 실패 알림 사용 여부
  func setAuthFailureAlertEnabled(_ enabled: Bool)

  /// 클립보드 반복 복사(비정상 접근) 알림 사용 여부.
  /// - Returns: 클립보드 반복 복사 알림 사용 여부
  func isClipboardAbnormalAccessAlertEnabled() -> Bool
  /// 클립보드 반복 복사 알림 사용 여부를 저장한다.
  /// - Parameter enabled: 클립보드 반복 복사 알림 사용 여부
  func setClipboardAbnormalAccessAlertEnabled(_ enabled: Bool)
}
