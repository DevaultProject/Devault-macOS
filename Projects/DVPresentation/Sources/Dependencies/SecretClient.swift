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
    fetchByQuery: { _ in [.preview] },
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

// MARK: - Preview Fixtures

extension Secret {
  static let preview = Secret(
    id: UUID(),
    name: "GitHub API Key",
    secretType: .apiKeyToken,
    createdAt: .now,
    updatedAt: .now,
    payload: SecretPayload(encryptedData: Data(), keyTag: "preview", schemaVersion: 1)
  )
}

public extension [Project] {
  static let preview: [Project] = [
    Project(id: UUID(), name: "CheerLot", createdAt: .now, updatedAt: .now),
    Project(id: UUID(), name: "Mobile", createdAt: .now, updatedAt: .now),
  ]
}
