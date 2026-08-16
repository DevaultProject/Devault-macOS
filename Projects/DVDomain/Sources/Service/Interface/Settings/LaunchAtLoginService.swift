// Copyright © 2026 Devault. All rights reserved

/// 시스템 로그인 항목의 등록 상태를 조회하고 변경하는 서비스입니다.
public protocol LaunchAtLoginService: Sendable {
  /// 현재 앱이 로그인 항목에 등록되어 있는지 확인한다.
  /// - Returns: 로그인 항목 등록 여부
  func isEnabled() -> Bool
  /// 앱의 로그인 항목 등록 상태를 변경한다.
  /// - Parameter enabled: 로그인 항목 등록 여부
  func setEnabled(_ enabled: Bool) throws
}
