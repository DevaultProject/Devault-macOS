// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

@DependencyClient
public struct ICloudSettingsClient: Sendable {
  public var isEnabled: @Sendable () -> Bool = { false }
  public var setEnabled: @Sendable (Bool) async throws -> Void
  public var openSystemSettings: @Sendable () -> Void
  public var lastUpdateDetectedAt: @Sendable () -> Date?
  /// CloudKit 원격 변경이 감지될 때마다 값을 방출한다.
  public var remoteChangeStream: @Sendable () -> AsyncStream<Void> = { AsyncStream { $0.finish() } }
  public var accountStatus: @Sendable () async -> ICloudAccountStatus = { .couldNotDetermine }
}

extension ICloudSettingsClient: TestDependencyKey {
  public static let testValue = ICloudSettingsClient()

  public static let previewValue = ICloudSettingsClient(
    isEnabled: { false },
    setEnabled: { _ in },
    openSystemSettings: { },
    lastUpdateDetectedAt: { nil },
    remoteChangeStream: { AsyncStream { $0.finish() } },
    accountStatus: { .available }
  )
}

extension DependencyValues {
  public var iCloudSettingsClient: ICloudSettingsClient {
    get { self[ICloudSettingsClient.self] }
    set { self[ICloudSettingsClient.self] = newValue }
  }
}
