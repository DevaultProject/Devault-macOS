// Copyright © 2026 Devault. All rights reserved

public protocol DataSettingsUseCase: Sendable {
    /// 삭제 변경이 iCloud에도 동기화되는 현재 저장소 구성인지 확인한다.
    func isICloudSyncEnabled() -> Bool
    /// 재인증 후 모든 Secret(휴지통 포함)과 Project를 영구 삭제한다. 되돌릴 수 없다.
    func deleteAllData() async throws
}
