// Copyright © 2026 Devault. All rights reserved

@testable import DVDomain

public final class FakeLaunchAtLoginService: LaunchAtLoginService, @unchecked Sendable {

  public enum Failure: Error, Equatable {
    case failed
  }

  public var isEnabledValue = false
  public var setEnabledError: Failure?

  public init() {}

  public func isEnabled() -> Bool {
    isEnabledValue
  }

  public func setEnabled(_ enabled: Bool) throws {
    if let setEnabledError {
      throw setEnabledError
    }

    isEnabledValue = enabled
  }
}
