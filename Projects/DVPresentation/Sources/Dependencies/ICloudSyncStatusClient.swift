// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

/// Settings의 iCloud 상태 카드 전용 Client. 계정 상태 확인은 순수 읽기 — `OnboardingClient.enableICloudSync`와
/// 달리 동기화 설정을 켜는 부작용이 없다.
@DependencyClient
public struct ICloudSyncStatusClient: Sendable {
  public var lastSyncedAt: @Sendable () -> Date? = { nil }
  public var setLastSyncedAt: @Sendable (Date) -> Void
  /// CloudKit 원격 변경이 감지될 때마다 값을 방출한다.
  public var remoteChangeStream: @Sendable () -> AsyncStream<Void> = { AsyncStream { $0.finish() } }
  public var accountStatus: @Sendable () async -> ICloudAccountStatus = { .couldNotDetermine }
  public var syncedSecretCount: @Sendable () async throws -> Int
  public var syncedProjectCount: @Sendable () async throws -> Int
}

extension ICloudSyncStatusClient: TestDependencyKey {
  public static let testValue = ICloudSyncStatusClient()

  public static let previewValue = ICloudSyncStatusClient(
    lastSyncedAt: { nil },
    setLastSyncedAt: { _ in },
    remoteChangeStream: { AsyncStream { $0.finish() } },
    accountStatus: { .available },
    syncedSecretCount: { 0 },
    syncedProjectCount: { 0 }
  )
}

extension DependencyValues {
  public var iCloudSyncStatusClient: ICloudSyncStatusClient {
    get { self[ICloudSyncStatusClient.self] }
    set { self[ICloudSyncStatusClient.self] = newValue }
  }
}
