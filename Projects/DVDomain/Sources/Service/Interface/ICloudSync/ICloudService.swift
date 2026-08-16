// Copyright © 2026 Devault. All rights reserved

/// 현재 기기의 iCloud 상태와 동기화 이벤트를 제공하는 서비스입니다.
public protocol ICloudService: Sendable {
    /// iCloud 계정 로그인 및 사용 가능 여부를 확인한다.
    func fetchAccountStatus() async -> ICloudAccountStatus

    /// 영구 저장소에 반영된 iCloud 원격 변경을 방출한다.
    func remoteChangeStream() -> AsyncStream<Void>

    /// iCloud 동기화 여부에 맞는 영구 저장소 구성을 적용한다.
    func configureStorage(iCloudSyncEnabled: Bool) async throws
}
