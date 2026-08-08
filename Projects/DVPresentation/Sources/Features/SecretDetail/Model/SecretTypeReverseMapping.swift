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
