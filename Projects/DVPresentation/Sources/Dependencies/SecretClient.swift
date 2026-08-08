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
  /// 생체인증 후 Secret의 암호화된 payload를 복호화해 `CreateSecretPayload`로 반환한다.
  /// secretType/subType에 따라 적절한 도메인 payload 타입으로 dispatch하고 metadata JSON을 병합한다.
  public var revealPayload: @Sendable (_ secret: Secret) async throws -> CreateSecretPayload

  // MARK: - Project

  public var fetchProjects: @Sendable () async throws -> [Project]
  public var createProject: @Sendable (_ name: String) async throws -> Project
  public var linkProject: @Sendable (_ secretID: Secret.ID, _ projectID: Project.ID) async throws -> Void
}

extension SecretClient: TestDependencyKey {
  public static let testValue = SecretClient()
  public static let previewValue = dummyClient()
}

private extension SecretClient {
  static func dummyClient() -> SecretClient {
    SecretClient(
      fetchByQuery: { query in
        let filtered: [Secret]
        switch query.collection {
        case .expired(let referenceDate):
          filtered = [Secret].preview.filter {
            $0.deletedAt == nil && ($0.expiresAt.map { $0 < referenceDate } ?? false)
          }
        case .deleted:
          filtered = [Secret].preview.filter { $0.deletedAt != nil }
        case .liked:
          filtered = [Secret].preview.filter { $0.deletedAt == nil && $0.liked }
        case .project(let id):
          filtered = [Secret].preview(in: id)
        case .all:
          filtered = [Secret].preview.filter { $0.deletedAt == nil }
        }
        return sorted(filtered, by: query.sort)
      },
      softDelete: { _ in .preview },
      restore: { _ in .preview },
      permanentlyDelete: { _ in },
      revealPayload: { secret in
          switch secret.secretType {
          case .apiKeyToken:
              return .apiKey(APIKeyPayload(value: "preview_api_key"), nil)
          case .oauth:
              return .oauthClient(
                OAuthClientPayload(clientId: "preview_id", clientSecret: "preview_secret"),
                nil
              )
          case .database:
              return .database(DatabasePayload(linkString: "postgresql://preview:5432/db"), nil)
          case .sshAndCredentials:
              return .sshKey(
                SSHKeyPayload(
                    privateKey: "-----BEGIN RSA PRIVATE KEY-----\npreview\n-----END RSA PRIVATE KEY-----",
                    passphrase: nil
                ),
                nil
              )
          case .environmentVariableSet:
              return .environmentVariableSet(EnvSetPayload(content: "KEY=value\nOTHER=123"))
          case .etc:
              return .licenseKey(LicenseKeyPayload(licenseKey: "PREVIEW-LICENSE-1234"), nil)
          }
      },
      fetchProjects: { .preview },
      createProject: { name in
          Project(id: UUID(), name: name, createdAt: .now, updatedAt: .now)
      },
      linkProject: { _, _ in }
    )
  }

  static func sorted(_ secrets: [Secret], by sort: SecretQuery.Sort) -> [Secret] {
    switch sort {
    case .recentlyAdded:
      return secrets.sorted { $0.createdAt > $1.createdAt }
    case .oldestFirst:
      return secrets.sorted { $0.createdAt < $1.createdAt }
    case .expiringSoon:
      return secrets.sorted { ($0.expiresAt ?? .distantFuture) < ($1.expiresAt ?? .distantFuture) }
    case .nameAscending:
      return secrets.sorted { $0.name < $1.name }
    case .nameDescending:
      return secrets.sorted { $0.name > $1.name }
    }
  }
}

public extension DependencyValues {
  var secretClient: SecretClient {
    get { self[SecretClient.self] }
    set { self[SecretClient.self] = newValue }
  }
}
