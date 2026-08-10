// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol FetchSecretUseCase: Sendable {
    /// ID로 단일 Secret을 조회한다.
    /// - Parameter id: 조회할 Secret의 ID
    /// - Returns: 해당 Secret. 존재하지 않으면 nil
    func fetch(id: UUID) async throws -> Secret?

    /// 쿼리 조건에 맞는 Secret 목록을 조회한다.
    /// - Parameter query: 필터·정렬 조건을 담은 SecretQuery
    /// - Returns: 조건에 부합하는 Secret 배열
    func fetch(query: SecretQuery) async throws -> [Secret]

    /// 쿼리 조건에 맞는 Secret의 개수만 조회한다. 사이드바 카운트처럼 목록 본문이 필요 없을 때 쓴다.
    /// - Parameter query: 필터 조건을 담은 SecretQuery. `sort`는 무시된다
    /// - Returns: 조건에 부합하는 Secret 개수
    func count(query: SecretQuery) async throws -> Int

    /// Secret에 연결된 Project 목록을 조회한다.
    /// - Parameter secretID: 조회할 Secret의 ID
    /// - Returns: 해당 Secret에 연결된 Project 배열
    func fetchProjects(secretID: UUID) async throws -> [Project]
}
