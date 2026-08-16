// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 인증, 자동 잠금, 클립보드와 화면 캡처 관련 보안 설정을 관리합니다.
public protocol SecuritySettingsUseCase: Sendable {
  /// 앱 실행 시 인증 요구 여부를 확인한다.
  /// - Returns: 앱 실행 시 인증 요구 여부
  func isRequireAuthOnLaunchEnabled() -> Bool
  /// 앱 실행 시 인증 요구 여부를 저장한다.
  /// - Parameter enabled: 앱 실행 시 인증 요구 여부
  func setRequireAuthOnLaunchEnabled(_ enabled: Bool)

  /// Secret 값 복사 시 인증 요구 여부를 확인한다.
  /// - Returns: Secret 값 복사 시 인증 요구 여부
  func isRequireAuthToCopyEnabled() -> Bool
  /// Secret 값 복사 시 인증 요구 여부를 저장한다.
  /// - Parameter enabled: Secret 값 복사 시 인증 요구 여부
  func setRequireAuthToCopyEnabled(_ enabled: Bool)

  /// 비활성 후 자동 잠금 사용 여부를 확인한다.
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

  /// 클립보드 자동 비우기 사용 여부를 확인한다.
  /// - Returns: 클립보드 자동 비우기 사용 여부
  func isAutoClearClipboardEnabled() -> Bool
  /// 클립보드 자동 비우기 사용 여부를 저장한다.
  /// - Parameter enabled: 클립보드 자동 비우기 사용 여부
  func setAutoClearClipboardEnabled(_ enabled: Bool)

  /// 클립보드 자동 비우기까지의 시간(초)을 반환한다.
  /// - Returns: 클립보드 자동 비우기까지의 시간(초)
  func autoClearClipboardDelaySeconds() -> Int
  /// 클립보드 자동 비우기까지의 시간(초)을 저장한다.
  /// - Parameter seconds: 저장할 클립보드 자동 비우기 시간(초)
  func setAutoClearClipboardDelaySeconds(_ seconds: Int)

  /// 앱 창 전체의 캡처 보호 여부를 확인한다.
  /// - Returns: 앱 창 전체의 캡처 보호 여부
  func isWindowCaptureProtectionEnabled() -> Bool
  /// 앱 창 전체의 캡처 보호 여부를 저장한다.
  /// - Parameter enabled: 앱 창 전체의 캡처 보호 여부
  func setWindowCaptureProtectionEnabled(_ enabled: Bool)

  /// 구독을 시작하면 현재 설정값을 즉시 한 번 방출하고, 이후 설정이 변경될 때마다 최신값을 방출한다.
  /// - Returns: 앱 창 전체의 캡처 보호 설정 스트림
  func windowCaptureProtectionEnabledStream() -> AsyncStream<Bool>
}
