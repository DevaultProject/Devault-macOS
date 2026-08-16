// Copyright © 2026 Devault. All rights reserved

/// 데이터 설정 화면에서 현재 저장소 상태를 확인하고 전체 데이터를 초기화합니다.
public protocol DataSettingsUseCase: Sendable {
    /// 삭제 변경이 iCloud에도 동기화되는 현재 저장소 구성인지 확인한다.
    /// - Returns: iCloud 동기화 저장소 사용 여부
    func isICloudSyncEnabled() -> Bool
    /// 재인증 후 모든 Secret(휴지통 포함)과 Project를 영구 삭제한다. 되돌릴 수 없다.
    func deleteAllData() async throws
}
