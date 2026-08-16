// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

@DependencyClient
public struct AppSecurityClient: Sendable {
  public var isRequireAuthOnLaunchEnabled: @Sendable () -> Bool = { true }
  public var inactivityTimeoutStream: @Sendable () -> AsyncStream<Void> = {
    AsyncStream { $0.finish() }
  }
}

extension AppSecurityClient: TestDependencyKey {
  public static let testValue = AppSecurityClient()
  public static let previewValue = AppSecurityClient()
}

extension DependencyValues {
  public var appSecurityClient: AppSecurityClient {
    get { self[AppSecurityClient.self] }
    set { self[AppSecurityClient.self] = newValue }
  }
}
