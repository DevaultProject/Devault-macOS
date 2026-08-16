// Copyright © 2026 Devault. All rights reserved

@testable import DVDomain

public final class FakeLaunchAtLoginService: LaunchAtLoginService, @unchecked Sendable {

  public enum Failure: Error, Equatable {
    case failed
  }

  public var statusValue: LaunchAtLoginStatus = .notRegistered
  public var setEnabledError: Failure?
  public private(set) var didOpenSystemSettings = false

  public init() {}

  public func status() -> LaunchAtLoginStatus {
    statusValue
  }

  public func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginStatus {
    if let setEnabledError {
      throw setEnabledError
    }

    statusValue = enabled ? .enabled : .notRegistered
    return statusValue
  }

  public func openSystemSettings() {
    didOpenSystemSettings = true
  }
}
