// Copyright © 2026 Devault. All rights reserved

/// 현재 활성 저장소의 Vault 항목을 초기화합니다.
public protocol DataResetRepository: Sendable {
    /// 모든 Secret, Project와 관련 동기화 데이터를 삭제한다.
    /// 기기 로컬 백업 기록과 Keychain 암호화 키는 백업 복구 가능성을 유지하기 위해 삭제하지 않는다.
    func deleteAll() async throws
}
