// Copyright © 2026 Devault. All rights reserved

import Foundation

/// iCloud 동기화 설정과 현재 저장소 구성을 관리합니다.
public protocol ICloudSettingsUseCase: Sendable {
  /// iCloud 동기화 사용 여부를 확인한다.
  /// - Returns: iCloud 동기화 사용 여부
  func isEnabled() -> Bool
  /// iCloud 동기화 사용 여부를 저장한다.
  /// - Parameter enabled: 사용 여부
  func setEnabled(_ enabled: Bool) async throws

  /// 현재 기기의 iCloud 계정 상태를 확인한다.
  /// - Returns: 현재 iCloud 계정 상태
  func accountStatus() async -> ICloudAccountStatus

  /// 영구 저장소에 반영된 iCloud 원격 변경을 방출한다.
  /// - Returns: iCloud 원격 변경 이벤트 스트림
  func remoteChangeStream() -> AsyncStream<Void>

  /// 마지막으로 CloudKit 원격 변경이 감지된 시각. 한 번도 없었으면 nil.
  /// - Returns: 마지막 원격 변경 감지 시각. 기록이 없으면 nil
  func lastSyncedAt() -> Date?
  /// 마지막 CloudKit 원격 변경 감지 시각을 저장한다.
  /// - Parameter date: 저장할 원격 변경 감지 시각
  func setLastSyncedAt(_ date: Date)
}
