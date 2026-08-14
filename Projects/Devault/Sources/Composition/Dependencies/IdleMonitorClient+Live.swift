// Copyright © 2026 Devault. All rights reserved

import CoreGraphics

import ComposableArchitecture
import DVPresentation

extension IdleMonitorClient: @retroactive DependencyKey {
  public static let liveValue: IdleMonitorClient = IdleMonitorClient(
    idleSecondsStream: {
      AsyncStream { continuation in
        let task = Task {
          while !Task.isCancelled {
            let idleSeconds = CGEventSource.secondsSinceLastEventType(
              .combinedSessionState,
              eventType: .null
            )
            continuation.yield(idleSeconds)
            try? await Task.sleep(for: .seconds(5))
          }
          continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
      }
    }
  )
}
