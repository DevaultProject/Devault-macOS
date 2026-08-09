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

  /// `dummyClient().revealPayload`가 분기하는 `(secretType, subType)` 11개 조합을 전수로 담아
  /// SecretDetail의 타입별 payload 섹션을 프리뷰로 확인하기 위한 픽스처.
  /// 아바타 폴백·컬렉션 필터가 목적인 `preview`(전부 `subType == nil`)와 달리 조합 커버리지가 목적이므로,
  /// 목록 계열 프리뷰는 `preview`를, 상세 화면 프리뷰는 이 배열을 쓴다.
  ///
  /// 조회 화면의 optional 메타 필드가 빈 상태로 렌더되는 경우도 함께 확인해야 해
  /// `service` / `environment` / `expiresAt` / `memo`는 채운 항목과 nil인 항목을 섞어 둔다.
  /// 각 항목은 **생성 화면이 그 타입에서 실제로 입력받는 필드만** 채운다.
  /// 입력 경로가 없는 필드를 채우면 실제 데이터에 존재할 수 없는 상태가 되어,
  /// 조회 화면에서 "값이 있는데 왜 안 보이지"로 오해하게 된다.
  ///
  /// | 타입 | Expire Date | Environment | Services |
  /// |---|---|---|---|
  /// | apiKeyToken · oauthClient · database · custom | ✓ | ✓ | ✓ |
  /// | serviceAccount · licenseKey | ✓ | ✗ | ✓ |
  /// | sshKey · sslTlsCertificate · envSet | ✗ | ✓ | ✗ |
  public static let previewSubTypeMatrix: [Secret] = [
    secret(
      name: "GitHub API 키 (apiKey)",
      type: .apiKeyToken,
      subType: .apiKey,
      service: "github",
      environment: SecretEnvironment.prod.rawValue,
      expiresAt: .now.addingTimeInterval(30 * 86_400),
      memo: "리포지토리 읽기 전용. 만료 2주 전 갱신.",
      liked: true
    ),
    // 메타 필드 전부 nil — 빈 상태 렌더링 확인용
    secret(
      name: "GitHub Access Token (accessToken)",
      type: .apiKeyToken,
      subType: .accessToken
    ),
    // 이미 만료된 항목 — Expired 컬렉션·만료 표시 확인용
    secret(
      name: "Stripe Webhook Secret (webhookSecret)",
      type: .apiKeyToken,
      subType: .webhookSecret,
      service: "Stripe",
      environment: SecretEnvironment.staging.rawValue,
      expiresAt: .now.addingTimeInterval(-86_400),
      memo: "결제 이벤트 서명 검증용."
    ),
    secret(
      name: "Google OAuth 클라이언트 (oauthClient)",
      type: .oauth,
      subType: .oauthClient,
      service: "google",
      expiresAt: .now.addingTimeInterval(90 * 86_400),
      liked: true
    ),
    secret(
      name: "GCP 서비스 계정 (serviceAccount)",
      type: .oauth,
      subType: .serviceAccount,
      service: "gcp",
      memo: "BigQuery 적재 배치 전용 계정."
    ),
    // database / environmentVariableSet은 availableSubTypes가 비어 있어 nil이 유일한 유효값
    secret(
      name: "CheerLot 운영 DB (subType 없음)",
      type: .database,
      service: "CheerLot",
      environment: SecretEnvironment.dev.rawValue
    ),
    secret(
      name: "배포 서버 SSH 키 (sshKey)",
      type: .sshAndCredentials,
      subType: .sshKey,
      environment: SecretEnvironment.prod.rawValue,
      memo: "passphrase 없음. 배포 파이프라인에서만 사용."
    ),
    // 생성 화면이 인증서 타입에서 Expire Date를 입력받지 않아 만료일이 비어 있다.
    // PEM의 notAfter로 산출하는 것은 별도 이슈다.
    secret(
      name: "devault.app 인증서 (sslTlsCertificate)",
      type: .sshAndCredentials,
      subType: .sslTlsCertificate,
      environment: SecretEnvironment.prod.rawValue,
      memo: "Let's Encrypt. certbot 자동 갱신."
    ),
    secret(
      name: "운영 .env 모음 (subType 없음)",
      type: .environmentVariableSet,
      environment: SecretEnvironment.staging.rawValue,
      memo: "배포 시 CI 시크릿과 동기화 필요.",
      liked: true
    ),
    secret(
      name: "Sketch 라이선스 키 (licenseKey)",
      type: .etc,
      subType: .licenseKey,
      expiresAt: .now.addingTimeInterval(365 * 86_400)
    ),
    // 여러 줄 memo — 상세 화면에서 줄바꿈 처리 확인용
    secret(
      name: "사내 커스텀 값 (custom)",
      type: .etc,
      subType: .custom,
      memo: """
      정해진 스키마가 없는 값.
      담당자: 플랫폼팀
      """
    ),
  ]

  private static func secret(
    name: String,
    type: SecretType,
    subType: SecretSubType? = nil,
    service: String? = nil,
    environment: String? = nil,
    expiresAt: Date? = nil,
    memo: String? = nil,
    liked: Bool = false,
    deletedAt: Date? = nil
  ) -> Secret {
    Secret(
      id: UUID(),
      name: name,
      secretType: type,
      subType: subType,
      service: service,
      environment: environment,
      expiresAt: expiresAt,
      memo: memo,
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
