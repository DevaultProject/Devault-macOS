// Copyright © 2026 Devault. All rights reserved

import Foundation
import DVDomain

// UserDefaults는 thread-safe하므로 @unchecked Sendable 허용
public struct SettingsRepositoryImpl: SettingsRepository, @unchecked Sendable {

  private let defaults: UserDefaults
  private let ubiquitousStore: NSUbiquitousKeyValueStore

  public init(
    defaults: UserDefaults = .standard,
    ubiquitousStore: NSUbiquitousKeyValueStore = .default
  ) {
    self.defaults = defaults
    self.ubiquitousStore = ubiquitousStore
  }

  public func hasCompletedOnboarding() -> Bool {
    defaults.bool(forKey: .hasCompletedOnboarding)
  }

  public func setOnboardingCompleted() {
    defaults.set(true, forKey: .hasCompletedOnboarding)
  }

  // iCloud 동기화 사용 여부는 기기가 아닌 사용자 단위 설정이라 NSUbiquitousKeyValueStore로 관리한다.
  // (hasCompletedOnboarding은 기기별로 Touch ID 확인을 다시 거쳐야 해서 로컬 UserDefaults 유지)
  public func isICloudSyncEnabled() -> Bool {
    ubiquitousStore.bool(forKey: .isICloudSyncEnabled)
  }

  public func setICloudSyncEnabled(_ enabled: Bool) {
    ubiquitousStore.set(enabled, forKey: .isICloudSyncEnabled)
  }
}
