// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

@DependencyClient
public struct DataSettingsClient: Sendable {
  /// 현재 활성 저장소가 iCloud 동기화 구성인지 확인한다.
  public var isICloudSyncEnabled: @Sendable () -> Bool = { false }
  /// 재인증 후 모든 Secret·Project를 영구 삭제한다. 되돌릴 수 없다.
  public var deleteAllData: @Sendable () async throws -> Void
}

extension DataSettingsClient: TestDependencyKey {
  public static let testValue = DataSettingsClient()
  public static let previewValue = DataSettingsClient(
    isICloudSyncEnabled: { true },
    deleteAllData: { }
  )
}

extension DependencyValues {
  public var dataSettingsClient: DataSettingsClient {
    get { self[DataSettingsClient.self] }
    set { self[DataSettingsClient.self] = newValue }
  }
}
