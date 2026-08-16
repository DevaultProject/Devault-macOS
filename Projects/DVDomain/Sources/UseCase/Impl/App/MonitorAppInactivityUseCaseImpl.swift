// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct MonitorAppInactivityUseCaseImpl: MonitorAppInactivityUseCase {

  private let service: any AppInactivityMonitorService
  private let repository: any SettingsRepository

  public init(
    service: any AppInactivityMonitorService,
    repository: any SettingsRepository
  ) {
    self.service = service
    self.repository = repository
  }

  public func timeoutStream() -> AsyncStream<Void> {
    AsyncStream { continuation in
      let task = Task {
        for await inactivitySeconds in service.inactivitySecondsStream() {
          guard !Task.isCancelled else { break }
          guard repository.isAutoLockEnabled() else { continue }

          let timeoutSeconds = TimeInterval(repository.autoLockMinutes() * 60)
          guard inactivitySeconds >= timeoutSeconds else { continue }

          continuation.yield(())
          break
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in task.cancel() }
    }
  }
}
