// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation

/// `SecretMetaFields` → 도메인 매핑 결과 컨테이너.
/// (secretType, subType) 조합별로 (Payload, Metadata?) 페어를 실은 enum.
/// 소비 지점에서 case 분기해 `CreateSecretUseCase.execute`의 두 overload(metadata 유무) 중 하나로 dispatch한다.
/// `Sendable`인 것은 이미 `@Sendable` Client 클로저(`revealPayload` · `createSecret` · `updateSecret`)를
/// 넘나들기 때문이다. 실린 payload·metadata 타입은 `SecretPayloadData` / `SecretMetadataContent`가
/// `Sendable`을 요구하므로 조건 없이 성립한다.
public enum CreateSecretPayload: Equatable, Sendable {
    case apiKey(APIKeyPayload, APIKeyMetadata?)
    case accessToken(APIKeyPayload, APIKeyMetadata?)
    case webhookSecret(APIKeyPayload, APIKeyMetadata?)

    case oauthClient(OAuthClientPayload, OAuthClientMetadata?)
    case serviceAccount(ServiceAccountPayload, ServiceAccountMetadata?)

    case database(DatabasePayload, DatabaseMetadata?)

    case sshKey(SSHKeyPayload, SSHKeyMetadata?)
    case sslTlsCertificate(SSLCertPayload, SSLCertMetadata?)

    /// EnvSet은 metadata 스키마 자체가 없음.
    case environmentVariableSet(EnvSetPayload)

    case licenseKey(LicenseKeyPayload, LicenseKeyMetadata?)

    /// Custom은 metadata 스키마 자체가 없음.
    case custom(CustomPayload)
}
