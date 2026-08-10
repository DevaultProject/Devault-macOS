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
}
