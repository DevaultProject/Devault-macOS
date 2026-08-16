// Copyright © 2026 Devault. All rights reserved

import DVDomain

// MARK: - Domain → Presentation 역변환

/// `CreatableSecretType.domainType` / `CreatableSecretSubType.domainSubType`의 역방향.
///
/// 조회·수정 화면은 `Secret`(도메인 타입)에서 출발하지만, 화면 표시 문자열(`displayName`)과
/// 서브탭 목록(`availableSubTypes`)은 Presentation enum이 소유한다. 따라서 도메인 → Presentation
/// 역변환이 필요하다.
///
/// 두 매핑 모두 케이스가 1:1로 완전 대응하므로(`SecretType` 6:6, `SecretSubType` 9:9)
/// Optional이나 실패 케이스가 없다. 도메인에 케이스가 추가되면 컴파일러가 여기서 잡는다.
extension SecretType {

    var creatableType: CreatableSecretType {
        switch self {
        case .apiKeyToken:            return .apiKeyToken
        case .oauth:                  return .oauth
        case .database:               return .database
        case .sshAndCredentials:      return .sshAndCredentials
        case .environmentVariableSet: return .environmentVariableSet
        case .etc:                    return .etc
        }
    }
}

extension CreatableSecretType {

    /// 저장된 서브타입을 폼·화면이 쓰는 값으로 바꾼다. **`nil`이면 이 타입의 첫 서브타입으로 본다.**
    ///
    /// `Secret.subType`은 도메인에서 optional이라 예전 데이터에는 비어 있을 수 있다. live
    /// `dispatchRevealPayload`가 `(.apiKeyToken, nil)`을 `.apiKey`로 처리하는 것과 같은 규칙이고,
    /// 여기서 갈리면 조회는 되는데 저장만 조용히 실패하는(`invalidTypeCombination`) 상태가 된다.
    ///
    /// 서브탭이 없는 타입(database · envSet)은 그대로 `nil`이다.
    func resolvedSubType(_ subType: SecretSubType?) -> CreatableSecretSubType? {
        subType?.creatableSubType ?? availableSubTypes.first
    }
}

extension SecretSubType {

    var creatableSubType: CreatableSecretSubType {
        switch self {
        case .apiKey:            return .apiKey
        case .accessToken:       return .accessToken
        case .webhookSecret:     return .webhookSecret
        case .oauthClient:       return .oauthClient
        case .serviceAccount:    return .serviceAccount
        case .sshKey:            return .sshKey
        case .sslTlsCertificate: return .sslTlsCertificate
        case .licenseKey:        return .licenseKey
        case .custom:            return .custom
        }
    }
}
