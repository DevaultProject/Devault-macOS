// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol ICloudSettingsUseCase: Sendable {
  /// iCloud 동기화 사용 여부를 확인한다.
  func isEnabled() -> Bool
  /// iCloud 동기화 사용 여부를 저장한다.
  /// - Parameter enabled: 사용 여부
  func setEnabled(_ enabled: Bool) async throws

  /// 현재 기기의 iCloud 계정 상태를 확인한다.
  func accountStatus() async -> ICloudAccountStatus

  /// 영구 저장소에 반영된 iCloud 원격 변경을 방출한다.
  func remoteChangeStream() -> AsyncStream<Void>

  /// 마지막으로 CloudKit 원격 변경이 감지된 시각. 한 번도 없었으면 nil.
  func lastSyncedAt() -> Date?
  func setLastSyncedAt(_ date: Date)
}
