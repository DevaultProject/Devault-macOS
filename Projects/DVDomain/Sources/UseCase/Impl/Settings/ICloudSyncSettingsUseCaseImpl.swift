// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct ICloudSyncSettingsUseCaseImpl: ICloudSyncSettingsUseCase {

  private let repository: any SettingsRepository

  public init(repository: any SettingsRepository) {
    self.repository = repository
  }

  public func isEnabled() -> Bool {
    repository.isICloudSyncEnabled()
  }

  public func setEnabled(_ enabled: Bool) {
    repository.setICloudSyncEnabled(enabled)
  }

  public func lastSyncedAt() -> Date? {
    repository.iCloudLastSyncedAt()
  }

  public func setLastSyncedAt(_ date: Date) {
    repository.setICloudLastSyncedAt(date)
  }
}
