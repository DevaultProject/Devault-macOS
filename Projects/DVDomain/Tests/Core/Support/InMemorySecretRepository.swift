// Copyright © 2026 Devault. All rights reserved

import Foundation

@testable import DVDomain

/// 도메인 계층 테스트용 in-memory Secret 저장소.
///
/// 실제 저장소 규약을 흉내내 duplicateID 등을 재현하며,
/// 각 메서드별로 에러 주입과 호출 카운트를 제공한다.
public final class InMemorySecretRepository: SecretRepository, @unchecked Sendable {
    public var secrets: [UUID: Secret] = [:]
    /// secretID → 연결된 projectID 집합
    public var projectLinks: [UUID: Set<UUID>] = [:]

    public var errorOnCreate: SecretRepositoryError?
    public var errorOnFetchByID: SecretRepositoryError?
    public var errorOnFetchQuery: SecretRepositoryError?
    public var errorOnPatch: SecretRepositoryError?
    public var errorOnDelete: SecretRepositoryError?
    public var errorOnFetchProjects: SecretRepositoryError?
    public var errorOnLinkProject: SecretRepositoryError?
    public var errorOnUnlinkProject: SecretRepositoryError?
    public var errorOnCreateWithProjects: SecretRepositoryError?
    public var errorOnPatchWithProjects: SecretRepositoryError?

    public private(set) var createCount = 0
    public private(set) var fetchByIDCount = 0
    public private(set) var fetchQueryCount = 0
    public private(set) var patchCount = 0
    public private(set) var deleteCount = 0
    public private(set) var fetchProjectsCount = 0
    public private(set) var linkProjectCount = 0
    public private(set) var unlinkProjectCount = 0
    public private(set) var createWithProjectsCount = 0
    public private(set) var patchWithProjectsCount = 0

    public private(set) var lastPatch: SecretPatch?
    public private(set) var lastProjectIDs: [UUID]?

    public init() {}

    public func seed(_ secret: Secret) { secrets[secret.id] = secret }

    // MARK: - SecretRepository

    public func create(_ secret: Secret) async throws -> Secret {
        createCount += 1
        if let error = errorOnCreate { throw error }
        guard secrets[secret.id] == nil else {
            throw SecretRepositoryError.duplicateID(id: secret.id)
        }
        secrets[secret.id] = secret
        return secret
    }

    public func fetch(id: UUID) async throws -> Secret? {
        fetchByIDCount += 1
        if let error = errorOnFetchByID { throw error }
        return secrets[id]
    }

    public func fetch(_ query: SecretQuery) async throws -> [Secret] {
        fetchQueryCount += 1
        if let error = errorOnFetchQuery { throw error }
        return Array(secrets.values)
    }

    public func patch(id: UUID, with patch: SecretPatch) async throws -> Secret {
        patchCount += 1
        lastPatch = patch
        if let error = errorOnPatch { throw error }
        guard var secret = secrets[id] else {
            throw SecretRepositoryError.notFound(id: id)
        }
        secret.apply(patch)
        secrets[id] = secret
        return secret
    }

    public func delete(id: UUID) async throws {
        deleteCount += 1
        if let error = errorOnDelete { throw error }
        guard secrets[id] != nil else {
            throw SecretRepositoryError.notFound(id: id)
        }
        secrets.removeValue(forKey: id)
    }

    public func fetchProjects(secretID: UUID) async throws -> [Project] {
        fetchProjectsCount += 1
        if let error = errorOnFetchProjects { throw error }
        guard secrets[secretID] != nil else {
            throw SecretRepositoryError.notFound(id: secretID)
        }
        return []
    }

    public func linkProject(secretID: UUID, projectID: UUID) async throws {
        linkProjectCount += 1
        if let error = errorOnLinkProject { throw error }
        guard secrets[secretID] != nil else {
            throw SecretRepositoryError.notFound(id: secretID)
        }
        projectLinks[secretID, default: []].insert(projectID)
    }

    public func unlinkProject(secretID: UUID, projectID: UUID) async throws {
        unlinkProjectCount += 1
        if let error = errorOnUnlinkProject { throw error }
        guard secrets[secretID] != nil else {
            throw SecretRepositoryError.notFound(id: secretID)
        }
        projectLinks[secretID]?.remove(projectID)
    }

    // MARK: - 원자적 생성·수정 (Project 연결 포함)

    public func create(_ secret: Secret, projectIDs: [UUID]) async throws -> Secret {
        createWithProjectsCount += 1
        lastProjectIDs = projectIDs
        if let error = errorOnCreateWithProjects { throw error }
        guard secrets[secret.id] == nil else {
            throw SecretRepositoryError.duplicateID(id: secret.id)
        }
        secrets[secret.id] = secret
        projectLinks[secret.id] = Set(projectIDs)
        return secret
    }

    public func patch(id: UUID, with patch: SecretPatch, projectIDs: [UUID]) async throws -> Secret {
        patchWithProjectsCount += 1
        lastPatch = patch
        lastProjectIDs = projectIDs
        if let error = errorOnPatchWithProjects { throw error }
        guard var secret = secrets[id] else {
            throw SecretRepositoryError.notFound(id: id)
        }
        secret.apply(patch)
        secrets[id] = secret
        projectLinks[id] = Set(projectIDs)
        return secret
    }
}

private extension Secret {
    mutating func apply(_ patch: SecretPatch) {
        if case let .set(name) = patch.name { self.name = name }
        if case let .set(secretType) = patch.secretType { self.secretType = secretType }
        if case let .set(subType) = patch.subType { self.subType = subType }
        if case let .set(service) = patch.service { self.service = service }
        if case let .set(environment) = patch.environment { self.environment = environment }
        if case let .set(expiresAt) = patch.expiresAt { self.expiresAt = expiresAt }
        if case let .set(memo) = patch.memo { self.memo = memo }
        if case let .set(liked) = patch.liked { self.liked = liked }
        if case let .set(deletedAt) = patch.deletedAt { self.deletedAt = deletedAt }
        if case let .set(payload) = patch.payload { self.payload = payload }
        if case let .set(metadata) = patch.metadata { self.metadata = metadata }
        if case let .set(updatedAt) = patch.updatedAt { self.updatedAt = updatedAt }
    }
}
