// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol DeleteSecretUseCase: Sendable {
    /// Secret을 소프트 삭제한다. deletedAt을 현재 시각으로 세팅하며 실제 데이터는 보존된다.
    /// - Parameter id: 삭제할 Secret의 ID
    /// - Returns: deletedAt이 설정된 Secret
    func softDelete(id: UUID) async throws -> Secret

    /// 소프트 삭제된 Secret을 복구한다. deletedAt을 nil로 되돌린다.
    /// - Parameter id: 복구할 Secret의 ID
    /// - Returns: 복구된 Secret
    func restore(id: UUID) async throws -> Secret

    /// Secret을 영구 삭제한다. 복구 불가.
    /// - Parameter id: 영구 삭제할 Secret의 ID
    func permanentlyDelete(id: UUID) async throws
}
