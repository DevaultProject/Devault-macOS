// Copyright © 2026 Devault. All rights reserved

import AppKit
import Foundation
import DVDomain

public struct AppInactivityMonitorServiceImpl: AppInactivityMonitorService {

  public init() {}

  public func interactionStream() -> AsyncStream<Void> {
    AsyncStream { continuation in
      let monitorHolder = EventMonitorHolder()
      let registrationTask = Task { @MainActor in
        guard !Task.isCancelled else { return }
        let monitor = NSEvent.addLocalMonitorForEvents(
          matching: Self.interactionEventMask
        ) { event in
          continuation.yield(())
          return event
        }
        monitorHolder.store(monitor)
      }

      continuation.onTermination = { _ in
        registrationTask.cancel()
        Task { @MainActor in
          await registrationTask.value
          if let monitor = monitorHolder.take() {
            NSEvent.removeMonitor(monitor)
          }
        }
      }
    }
  }
}

private final class EventMonitorHolder: @unchecked Sendable {

  private let lock = NSLock()
  private var monitor: Any?

  func store(_ monitor: Any?) {
    lock.lock()
    self.monitor = monitor
    lock.unlock()
  }

  func take() -> Any? {
    lock.lock()
    defer { lock.unlock() }
    defer { monitor = nil }
    return monitor
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
