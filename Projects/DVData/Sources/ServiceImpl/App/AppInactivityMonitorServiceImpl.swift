// Copyright © 2026 Devault. All rights reserved

import AppKit
import Foundation

import DVDomain

public struct AppInactivityMonitorServiceImpl: AppInactivityMonitorService {

  public init() {}

  public func inactivitySecondsStream() -> AsyncStream<TimeInterval> {
    AsyncStream { continuation in
      let timestamp = InteractionTimestamp()
      let task = Task { @MainActor in
        let monitor = NSEvent.addLocalMonitorForEvents(
          matching: Self.interactionEventMask
        ) { event in
          timestamp.recordInteraction()
          return event
        }

        while !Task.isCancelled {
          continuation.yield(timestamp.inactivitySeconds())

          do {
            try await Task.sleep(for: .seconds(1))
          } catch {
            break
          }
        }

        if let monitor {
          NSEvent.removeMonitor(monitor)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in task.cancel() }
    }
  }
}

extension AppInactivityMonitorServiceImpl {

  private static let interactionEventMask: NSEvent.EventTypeMask = [
    .keyDown,
    .flagsChanged,
    .mouseMoved,
    .leftMouseDown,
    .rightMouseDown,
    .otherMouseDown,
    .leftMouseDragged,
    .rightMouseDragged,
    .otherMouseDragged,
    .scrollWheel,
  ]
}

private final class InteractionTimestamp: @unchecked Sendable {

  private let lock = NSLock()
  private var lastInteractionUptime = ProcessInfo.processInfo.systemUptime

  func recordInteraction() {
    lock.lock()
    lastInteractionUptime = ProcessInfo.processInfo.systemUptime
    lock.unlock()
  }

  func inactivitySeconds() -> TimeInterval {
    lock.lock()
    defer { lock.unlock() }
    return ProcessInfo.processInfo.systemUptime - lastInteractionUptime
  }
}
