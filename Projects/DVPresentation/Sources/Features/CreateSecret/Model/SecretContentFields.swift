// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Foundation

/// `SecretMetaFields.content`가 담는 type-specific 필드 컨테이너.
/// (secretType, subType) 조합마다 대응 case가 있고, subType이 바뀔 때 case 교체로 이전 값이 자동 clear된다.
/// `apiKeyToken` 3개 서브타입(apiKey/accessToken/webhookSecret)은 payload 스키마가 동일하므로 하나의 case 공유.
@CasePathable
enum SecretContentFields: Equatable {
    case apiKeyToken(APIKeyTokenFields)
    case oauthClient(OAuthClientFields)
    case serviceAccount(ServiceAccountFields)
    case database(DatabaseFields)
    case sshKey(SSHKeyFields)
    case sslTlsCertificate(SSLCertFields)
    case envSet(EnvSetFields)
    case licenseKey(LicenseKeyFields)
    case custom(CustomFields)
    
    /// (secretType, subType) 조합에 대응하는 빈 초기 case를 반환.
    /// State init과 subType 스위칭 액션 두 지점에서 호출된다.
    /// subType이 nil인 경우엔 secretType의 대표 case로 폴백.
    static func `default`(
        for type: CreatableSecretType,
        subType: CreatableSecretSubType?
    ) -> SecretContentFields {
        switch (type, subType) {
        case (.apiKeyToken, _):
            return .apiKeyToken(APIKeyTokenFields())
        case (.oauth, .serviceAccount):
            return .serviceAccount(ServiceAccountFields())
        case (.oauth, _):
            return .oauthClient(OAuthClientFields())
        case (.database, _):
            return .database(DatabaseFields())
        case (.sshAndCredentials, .sslTlsCertificate):
            return .sslTlsCertificate(SSLCertFields())
        case (.sshAndCredentials, _):
            return .sshKey(SSHKeyFields())
        case (.environmentVariableSet, _):
            return .envSet(EnvSetFields())
        case (.etc, .custom):
            return .custom(CustomFields())
        case (.etc, _):
            return .licenseKey(LicenseKeyFields())
        }
    }
}

// MARK: - Sub-struct payload

/// apiKey / accessToken / webhookSecret 서브타입이 공유.
/// 세 서브타입은 payload 스키마가 완전히 동일해 필드를 함께 쓴다 — 서브타입 간 스위칭 시엔 값이 유지된다.
struct APIKeyTokenFields: Equatable {
    var value: String = ""
    /// `APIKeyMetadata.scope`. optional.
    var scope: String = ""
}

struct OAuthClientFields: Equatable {
    var clientId: String = ""
    var clientSecret: String = ""
    var redirectUri: String = ""
    var scopes: String = ""
}

struct ServiceAccountFields: Equatable {
    var credentialJSON: String = ""
    /// `ServiceAccountMetadata.authority`. optional. UI 라벨은 "Authority / Scope".
    var authority: String = ""
}

struct DatabaseFields: Equatable {
    var linkString: String = ""
    /// `DatabaseMetadata.sslRequired`. 사용자 명시 토글, 기본 false.
    var sslRequired: Bool = false
}

struct SSHKeyFields: Equatable {
    var privateKey: String = ""
    var passphrase: String = ""
    var publicKey: String = ""
    var host: String = ""
    var username: String = ""
}

struct SSLCertFields: Equatable {
    var certificate: String = ""
    /// SSH의 `privateKey`와 필드명 충돌 회피용. `SSLCertPayload.privateKey`로 매핑.
    var sslPrivateKey: String = ""
    var certificateChain: String = ""
    /// `SSLCertMetadata.renewCommand`. optional.
    var renewCommand: String = ""
}

struct EnvSetFields: Equatable {
    var envContent: String = ""
}

struct LicenseKeyFields: Equatable {
    var licenseKey: String = ""
    var licenseTier: LicenseTier = .individual
    /// `LicenseKeyMetadata.registrationEmail`. UI 라벨은 "Support Email"로 별도 표기.
    var registrationEmail: String = ""
    var orderNumber: String = ""
    var website: String = ""
}

struct CustomFields: Equatable {
    var value: String = ""
}
