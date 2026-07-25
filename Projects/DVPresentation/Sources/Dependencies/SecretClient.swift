// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

/// SecretList / AddToProject / CreateProject Feature가 공유하는 Secret·Project Client.
/// Live 조립은 Devault(App 타겟)에서 각 UseCase를 wrap한다.
@DependencyClient
public struct SecretClient: Sendable {

  // MARK: - Secret

  public var fetchByQuery: @Sendable (_ query: SecretQuery) async throws -> [Secret]
  public var softDelete: @Sendable (_ id: Secret.ID) async throws -> Secret
  public var restore: @Sendable (_ id: Secret.ID) async throws -> Secret
  public var permanentlyDelete: @Sendable (_ id: Secret.ID) async throws -> Void

  // MARK: - Project

  public var fetchProjects: @Sendable () async throws -> [Project]
  public var createProject: @Sendable (_ name: String) async throws -> Project
  public var linkProject: @Sendable (_ secretID: Secret.ID, _ projectID: Project.ID) async throws -> Void
}

extension SecretClient: TestDependencyKey {
  public static let testValue = SecretClient()

  public static let previewValue = SecretClient(
    fetchByQuery: { query in
      switch query.collection {
      case .expired(let referenceDate):
        return [Secret].preview.filter {
          $0.deletedAt == nil && ($0.expiresAt.map { $0 < referenceDate } ?? false)
        }
      case .deleted:
        return [Secret].preview.filter { $0.deletedAt != nil }
      case .liked:
        return [Secret].preview.filter { $0.deletedAt == nil && $0.liked }
      case .project(let id):
        return [Secret].preview(in: id)
      case .all:
        return [Secret].preview.filter { $0.deletedAt == nil }
      }
    },
    softDelete: { _ in .preview },
    restore: { _ in .preview },
    permanentlyDelete: { _ in },
    fetchProjects: { .preview },
    createProject: { name in
      Project(id: UUID(), name: name, createdAt: .now, updatedAt: .now)
    },
    linkProject: { _, _ in }
  )
}

public extension DependencyValues {
  var secretClient: SecretClient {
    get { self[SecretClient.self] }
    set { self[SecretClient.self] = newValue }
  }
}
