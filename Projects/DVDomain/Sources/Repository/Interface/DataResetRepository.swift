// Copyright © 2026 Devault. All rights reserved

/// 현재 활성 저장소의 Vault 데이터를 초기화한다.
public protocol DataResetRepository: Sendable {
    /// 모든 Secret, Project와 관련 동기화 데이터를 삭제한다.
    func deleteAll() async throws
}
