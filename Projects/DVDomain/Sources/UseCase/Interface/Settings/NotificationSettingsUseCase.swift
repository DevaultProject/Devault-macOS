// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 보안 및 만료 알림 설정을 조회하고 변경합니다.
public protocol NotificationSettingsUseCase: Sendable {
  /// 만료 알림 사용 여부를 확인한다.
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

  /// 반복 인증 실패 알림 사용 여부를 확인한다.
  /// - Returns: 반복 인증 실패 알림 사용 여부
  func isAuthFailureAlertEnabled() -> Bool
  /// 반복 인증 실패 알림 사용 여부를 저장한다.
  /// - Parameter enabled: 반복 인증 실패 알림 사용 여부
  func setAuthFailureAlertEnabled(_ enabled: Bool)

  /// 클립보드 반복 복사 알림 사용 여부를 확인한다.
  /// - Returns: 클립보드 반복 복사 알림 사용 여부
  func isClipboardAbnormalAccessAlertEnabled() -> Bool
  /// 클립보드 반복 복사 알림 사용 여부를 저장한다.
  /// - Parameter enabled: 클립보드 반복 복사 알림 사용 여부
  func setClipboardAbnormalAccessAlertEnabled(_ enabled: Bool)
}
