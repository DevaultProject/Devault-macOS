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
      case .all, .liked, .project:
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

// MARK: - Preview Fixtures

extension Secret {
  static let preview = Secret(
    id: UUID(),
    name: "GitHub API Key",
    secretType: .apiKeyToken,
    service: "github",
    createdAt: .now,
    updatedAt: .now,
    payload: SecretPayload(encryptedData: Data(), keyTag: "preview", schemaVersion: 1)
  )
}

public extension [Secret] {
  /// 아바타 폴백 3단계(로고 매칭 → service 첫 글자 → secretType 아이콘)를
  /// 타입 6종에 걸쳐 전부 확인하기 위한 프리뷰 픽스처.
  static let preview: [Secret] = [
    // 1) 로고 매칭
    .preview, // GitHub API Key · service: "github"
    secret(name: "Google 계정",   type: .oauth, service: "google"),
    secret(name: "네이버 계정",    type: .oauth, service: "naver"),
    secret(name: "카카오톡 계정",  type: .oauth, service: "kakaotalk"),

    // 2) 매칭 실패, service 첫 글자로 폴백
    secret(name: "Stripe API Key", type: .apiKeyToken, service: "Stripe"),
    secret(name: "CheerLot DB",    type: .database,    service: "CheerLot"),

    // 3) service 없음, secretType 아이콘으로 폴백
    secret(name: "이름 없는 API 키",  type: .apiKeyToken, expiresAt: .now.addingTimeInterval(-86_400)),
    secret(name: "사내 SSO",         type: .oauth),
    secret(name: "운영 DB",          type: .database, expiresAt: .now.addingTimeInterval(3 * 86_400)),
    secret(name: "배포 서버 SSH 키",  type: .sshAndCredentials, expiresAt: .now.addingTimeInterval(20 * 86_400)),
    secret(name: ".env 모음",        type: .environmentVariableSet),
    secret(name: "라이선스 키",       type: .etc),

    // 4) Deleted 컬렉션 전용
    secret(name: "삭제된 API 키", type: .apiKeyToken, deletedAt: .now),
  ]

  private static func secret(
    name: String,
    type: SecretType,
    service: String? = nil,
    expiresAt: Date? = nil,
    deletedAt: Date? = nil
  ) -> Secret {
    Secret(
      id: UUID(),
      name: name,
      secretType: type,
      service: service,
      expiresAt: expiresAt,
      deletedAt: deletedAt,
      createdAt: .now,
      updatedAt: .now,
      payload: SecretPayload(encryptedData: Data(), keyTag: "preview", schemaVersion: 1)
    )
  }
}

public extension [Project] {
  static let preview: [Project] = [
    Project(id: UUID(), name: "CheerLot", createdAt: .now, updatedAt: .now),
    Project(id: UUID(), name: "Mobile", createdAt: .now, updatedAt: .now),
  ]
}
