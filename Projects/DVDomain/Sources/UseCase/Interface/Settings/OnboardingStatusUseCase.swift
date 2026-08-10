// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol OnboardingStatusUseCase: Sendable {
  /// 온보딩을 완료했는지 확인한다.
  func hasCompleted() -> Bool
  /// 온보딩 완료 상태를 저장한다.
  func setCompleted()
}
