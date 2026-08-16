// Copyright © 2026 Devault. All rights reserved

import Foundation

@testable import DVDomain

public final class FakeAppInactivityMonitorService: AppInactivityMonitorService, @unchecked Sendable {

  public var inactivitySecondsValues: [TimeInterval] = []

  public init() {}

  public func inactivitySecondsStream() -> AsyncStream<TimeInterval> {
    let values = inactivitySecondsValues
    return AsyncStream { continuation in
      for value in values {
        continuation.yield(value)
      }
      continuation.finish()
    }
  }
}
