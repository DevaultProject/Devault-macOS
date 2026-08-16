// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation

extension SecretMetaFields {

    /// 조회 중인 시크릿을 수정 폼의 초기값으로 되돌린다.
    /// `toSecretDraft` / `toCreateSecretPayload`의 역방향이다.
    ///
    /// **`payload`를 따로 받는 이유는 `secret.payload`가 암호문이기 때문이다.** type-specific 필드는
    /// 평문에서만 만들 수 있으므로, 수정 진입은 복호화(= 인증)를 먼저 통과해야 한다.
    ///
    /// - Parameter projectIds: 이 시크릿에 연결된 Project ID. `Secret` 엔티티에 프로젝트 정보가 없어
    ///   별도 조회한 값을 넘긴다(조회 화면은 chip 라벨 때문에 엔티티로 들고 있으므로 ID만 뽑아 전달).
    init(secret: Secret, payload: CreateSecretPayload, projectIds: [Project.ID]) {
        self.init(
            content: payload.contentFields,
            name: secret.name,
            projectIds: projectIds,
            service: secret.service ?? "",
            // 도메인은 `expiresAt`, 폼은 `expireDate` — 이름이 다르다.
            expireDate: secret.expiresAt,
            // 저장된 문자열이 폼 enum에 없으면 기본값으로 떨어뜨린다. 화면에서 다시 고를 수 있으므로
            // 진입을 막을 사유는 아니다 (`licenseTier`도 같은 규칙).
            environment: secret.environment.flatMap(SecretEnvironment.init(rawValue:)) ?? .dev,
            memo: secret.memo ?? ""
        )
    }
}
