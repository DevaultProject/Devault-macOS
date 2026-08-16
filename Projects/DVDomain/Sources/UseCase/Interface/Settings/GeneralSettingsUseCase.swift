// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 일반 설정의 로그인 시 실행과 기본 환경 정책을 제공합니다.
public protocol GeneralSettingsUseCase: Sendable {
  /// 현재 앱의 로그인 항목 등록 및 승인 상태를 확인한다.
  /// - Returns: 로그인 항목 상태
  func launchAtLoginStatus() -> LaunchAtLoginStatus
  /// 시스템 로그인 항목과 저장된 설정을 함께 변경한다.
  /// - Parameter enabled: 로그인 시 자동 실행 여부
  /// - Returns: 변경 요청 이후 로그인 항목 상태
  func setLaunchAtLoginEnabled(_ enabled: Bool) throws -> LaunchAtLoginStatus
  /// 시스템 설정의 로그인 항목 화면을 연다.
  func openLoginItemsSystemSettings()

  /// 새 Secret 생성 시 적용할 기본 환경(rawValue)을 반환한다.
  /// - Returns: 기본 환경의 rawValue
  func defaultEnvironment() -> String
  /// 새 Secret 생성 시 적용할 기본 환경(rawValue)을 저장한다.
  /// - Parameter rawValue: 저장할 기본 환경의 rawValue
  func setDefaultEnvironment(_ rawValue: String)
}
