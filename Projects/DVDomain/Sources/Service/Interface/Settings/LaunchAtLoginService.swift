// Copyright © 2026 Devault. All rights reserved

/// 시스템 로그인 항목의 등록 상태를 조회하고 변경하는 서비스입니다.
public protocol LaunchAtLoginService: Sendable {
  /// 현재 앱의 로그인 항목 상태를 확인한다.
  /// - Returns: 로그인 항목 상태
  func status() -> LaunchAtLoginStatus
  /// 앱의 로그인 항목 등록 상태를 변경한다.
  /// - Parameter enabled: 로그인 항목 등록 여부
  /// - Returns: 변경 요청 이후 로그인 항목 상태
  func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginStatus
  /// 시스템 설정의 로그인 항목 화면을 연다.
  func openSystemSettings()
}

/// 시스템 로그인 항목의 등록 및 승인 상태입니다.
public enum LaunchAtLoginStatus: Equatable, Sendable {
  case notRegistered
  case enabled
  case requiresApproval
  case notFound

  /// 사용자가 로그인 시 실행을 요청해 시스템에 등록된 상태인지 여부.
  public var isRegistered: Bool {
    switch self {
    case .enabled, .requiresApproval:
      true
    case .notRegistered, .notFound:
      false
    }
  }
}
