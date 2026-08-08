// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol SecretRepository: Sendable {
    /// Secret을 저장소에 생성한다.
    /// - Parameter secret: 저장할 Secret 엔티티
    /// - Returns: 저장된 Secret
    func create(_ secret: Secret) async throws -> Secret

    /// ID로 단일 Secret을 조회한다.
    /// - Parameter id: 조회할 Secret의 ID
    /// - Returns: 해당 Secret. 존재하지 않으면 nil
    func fetch(id: UUID) async throws -> Secret?

    /// 쿼리 조건에 맞는 Secret 목록을 조회한다.
    /// - Parameter query: 필터·정렬 조건을 담은 SecretQuery
    /// - Returns: 조건에 부합하는 Secret 배열
    func fetch(_ query: SecretQuery) async throws -> [Secret]

    /// 쿼리 조건에 맞는 Secret의 개수만 조회한다.
    /// 엔티티를 메모리로 올리지 않으므로 `fetch(_:).count`보다 가볍고,
    /// 손상된 레코드가 섞여 있어도 개수 집계는 실패하지 않는다.
    /// - Parameter query: 필터 조건을 담은 SecretQuery. `sort`는 무시된다
    /// - Returns: 조건에 부합하는 Secret 개수
    func count(_ query: SecretQuery) async throws -> Int

    /// Secret의 지정 필드를 수정한다.
    /// - Parameters:
    ///   - id: 수정할 Secret의 ID
    ///   - patch: 변경할 필드만 담은 SecretPatch
    /// - Returns: 수정된 Secret
    func patch(id: UUID, with patch: SecretPatch) async throws -> Secret

    /// Secret을 영구 삭제한다.
    /// - Parameter id: 삭제할 Secret의 ID
    func delete(id: UUID) async throws

    /// Secret에 연결된 Project 목록을 조회한다.
    /// - Parameter secretID: 조회할 Secret의 ID
    /// - Returns: 해당 Secret에 연결된 Project 배열
    func fetchProjects(secretID: UUID) async throws -> [Project]

    /// Secret을 Project에 연결한다.
    /// - Parameters:
    ///   - secretID: 연결할 Secret의 ID
    ///   - projectID: 연결 대상 Project의 ID
    func linkProject(secretID: UUID, projectID: UUID) async throws

    /// Secret과 Project의 연결을 해제한다.
    /// - Parameters:
    ///   - secretID: 연결 해제할 Secret의 ID
    ///   - projectID: 연결 해제 대상 Project의 ID
    func unlinkProject(secretID: UUID, projectID: UUID) async throws

    /// Secret 생성과 Project 연결을 단일 트랜잭션으로 처리한다.
    /// 실패 시 ModelContext가 자동 롤백하므로 partial state가 발생하지 않는다.
    /// - Parameters:
    ///   - secret: 저장할 Secret 엔티티
    ///   - projectIDs: 연결할 Project ID 목록. 중복은 무시된다
    /// - Returns: 저장된 Secret
    func create(_ secret: Secret, projectIDs: [UUID]) async throws -> Secret

    /// Secret 필드 수정과 Project 연결 재조정을 단일 트랜잭션으로 처리한다.
    /// 현재 연결 상태와 projectIDs를 비교해 link/unlink를 결정한다.
    /// 실패 시 ModelContext가 자동 롤백하므로 partial state가 발생하지 않는다.
    /// - Parameters:
    ///   - id: 수정할 Secret의 ID
    ///   - patch: 변경할 필드만 담은 SecretPatch
    ///   - projectIDs: 수정 후 연결되어야 할 Project ID 목록
    /// - Returns: 수정된 Secret
    func patch(id: UUID, with patch: SecretPatch, projectIDs: [UUID]) async throws -> Secret
}
