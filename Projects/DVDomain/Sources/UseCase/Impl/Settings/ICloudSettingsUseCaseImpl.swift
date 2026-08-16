// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct ICloudSettingsUseCaseImpl: ICloudSettingsUseCase {

  private let repository: any SettingsRepository
  private let iCloudService: any ICloudService

  public init(
    repository: any SettingsRepository,
    iCloudService: any ICloudService
  ) {
    self.repository = repository
    self.iCloudService = iCloudService
  }

  public func isEnabled() -> Bool {
    repository.isICloudSyncEnabled()
  }

  public func setEnabled(_ enabled: Bool) async throws {
    try await iCloudService.configureStorage(iCloudSyncEnabled: enabled)
    repository.setICloudSyncEnabled(enabled)
  }

  public func accountStatus() async -> ICloudAccountStatus {
    await iCloudService.fetchAccountStatus()
  }

  public func remoteChangeStream() -> AsyncStream<Void> {
    iCloudService.remoteChangeStream()
  }

  public func lastUpdateDetectedAt() -> Date? {
    repository.iCloudLastUpdateDetectedAt()
  }

  public func setLastUpdateDetectedAt(_ date: Date) {
    repository.setICloudLastUpdateDetectedAt(date)
  }
}
