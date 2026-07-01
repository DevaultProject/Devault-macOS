// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol SecretProjectRelationUseCase: Sendable {
    /// Secret을 Project에 연결한다. Project 화면 등 단독 연결 조작에 사용한다.
    /// - Parameters:
    ///   - secretID: 연결할 Secret의 ID
    ///   - projectID: 연결 대상 Project의 ID
    func link(secretID: UUID, projectID: UUID) async throws

    /// Secret과 Project의 연결을 해제한다. Project 화면 등 단독 해제 조작에 사용한다.
    /// - Parameters:
    ///   - secretID: 연결 해제할 Secret의 ID
    ///   - projectID: 연결 해제 대상 Project의 ID
    func unlink(secretID: UUID, projectID: UUID) async throws
}
