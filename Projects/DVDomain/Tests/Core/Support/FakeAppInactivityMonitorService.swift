// Copyright © 2026 Devault. All rights reserved

@testable import DVDomain

public final class FakeAppInactivityMonitorService: AppInactivityMonitorService, @unchecked Sendable {

  public var interactionStreamValue: AsyncStream<Void>?

  public init() {}

  public func interactionStream() -> AsyncStream<Void> {
    if let interactionStreamValue {
      return interactionStreamValue
    }
    return AsyncStream { _ in }
  }
}
