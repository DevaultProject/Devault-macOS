// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 온보딩 완료 상태를 조회하고 저장합니다.
public protocol OnboardingStatusUseCase: Sendable {
  /// 온보딩을 완료했는지 확인한다.
  /// - Returns: 온보딩 완료 여부
  func hasCompleted() -> Bool
  /// 온보딩 완료 상태를 저장한다.
  func setCompleted()
}
