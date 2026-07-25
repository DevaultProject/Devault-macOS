// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVDomain

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

extension [Secret] {
  /// 아바타 폴백 3단계(로고 매칭 → service 첫 글자 → secretType 아이콘)를
  /// 타입 6종에 걸쳐 전부 확인하기 위한 프리뷰 픽스처.
  public static let preview: [Secret] = previewFixtures.map(\.secret)

  /// `.project` 컬렉션 필터링용. `Secret`엔 프로젝트 소속 필드가 없어(실제로는 별도 조인 테이블) 프리뷰에서만 매핑을 들고 있는다.
  public static func preview(in projectID: Project.ID) -> [Secret] {
    previewFixtures
      .filter { $0.secret.deletedAt == nil && $0.projectIDs.contains(projectID) }
      .map(\.secret)
  }

  private static let previewFixtures: [(secret: Secret, projectIDs: Set<UUID>)] = {
    let cheerLotID = [Project].preview[0].id

    return [
      // 1) 로고 매칭
      (.preview, [cheerLotID]), // GitHub API Key · service: "github"
      (secret(name: "Google 계정",   type: .oauth, service: "google"), [cheerLotID]),
      (secret(name: "네이버 계정",    type: .oauth, service: "naver"), []),
      (secret(name: "카카오톡 계정",  type: .oauth, service: "kakaotalk"), []),

      // 2) 매칭 실패, service 첫 글자로 폴백
      (secret(name: "Stripe API Key", type: .apiKeyToken, service: "Stripe"), []),
      (secret(name: "CheerLot DB",    type: .database,    service: "CheerLot"), [cheerLotID]),

      // 3) service 없음, secretType 아이콘으로 폴백
      (secret(name: "이름 없는 API 키",  type: .apiKeyToken, expiresAt: .now.addingTimeInterval(-86_400)), []),
      (secret(name: "사내 SSO",         type: .oauth), []),
      (secret(name: "운영 DB",          type: .database, expiresAt: .now.addingTimeInterval(3 * 86_400)), []),
      (secret(name: "배포 서버 SSH 키",  type: .sshAndCredentials, expiresAt: .now.addingTimeInterval(20 * 86_400)), []),
      (secret(name: ".env 모음",        type: .environmentVariableSet), []),
      (secret(name: "라이선스 키",       type: .etc), []),

      // 4) Deleted 컬렉션 전용
      (secret(name: "삭제된 API 키", type: .apiKeyToken, deletedAt: .now), []),

      // 5) Star(liked) 컬렉션 전용
      (secret(name: "즐겨찾는 API 키", type: .apiKeyToken, liked: true), []),
    ]
  }()

  private static func secret(
    name: String,
    type: SecretType,
    service: String? = nil,
    expiresAt: Date? = nil,
    liked: Bool = false,
    deletedAt: Date? = nil
  ) -> Secret {
    Secret(
      id: UUID(),
      name: name,
      secretType: type,
      service: service,
      expiresAt: expiresAt,
      liked: liked,
      deletedAt: deletedAt,
      createdAt: .now,
      updatedAt: .now,
      payload: SecretPayload(encryptedData: Data(), keyTag: "preview", schemaVersion: 1)
    )
  }
}

extension [Project] {
  public static let preview: [Project] = [
    Project(id: UUID(), name: "CheerLot", createdAt: .now, updatedAt: .now),
    Project(id: UUID(), name: "Mobile", createdAt: .now, updatedAt: .now),
  ]
}
