// Copyright © 2026 Devault. All rights reserved

import DVDomain

// MARK: - payload → 폼 필드 역변환

/// 복호화된 payload를 수정 폼의 type-specific 필드로 되돌린다.
/// `SecretMetaFields+Mapping`의 payload·metadata 조립을 정확히 되감는 방향이다.
///
/// **11 → 9로 줄어든다.** `apiKey` / `accessToken` / `webhookSecret`은 payload 스키마가 같아
/// `.apiKeyToken` 한 case를 공유하기 때문이다(`SecretContentFields`). 어느 서브타입이었는지는
/// 이 값이 아니라 `Secret.subType`이 들고 있다.
///
/// **`nil`은 빈 문자열이 된다.** 폼은 "미입력"을 `""`로만 표현하고, 저장할 때 `nilIfEmpty`가 다시
/// `nil`로 접는다. 그래서 왕복해도 같은 값으로 돌아온다.
extension CreateSecretPayload {

    var contentFields: SecretContentFields {
        switch self {
        // 세 서브타입이 payload·metadata 스키마를 공유하므로 한 case로 접는다.
        case .apiKey(let payload, let metadata),
             .accessToken(let payload, let metadata),
             .webhookSecret(let payload, let metadata):
            return .apiKeyToken(
                APIKeyTokenFields(
                    value: payload.value,
                    authorityScope: metadata?.scope ?? ""
                )
            )

        case .oauthClient(let payload, let metadata):
            return .oauthClient(
                OAuthClientFields(
                    clientId: payload.clientId,
                    clientSecret: payload.clientSecret,
                    redirectUri: metadata?.redirectUri ?? "",
                    scopes: metadata?.scopes ?? ""
                )
            )

        case .serviceAccount(let payload, let metadata):
            return .serviceAccount(
                ServiceAccountFields(
                    credentialJSON: payload.credentialJSON,
                    authority: metadata?.authority ?? ""
                )
            )

        // metadata가 없는 기존 레코드는 "SSL 안 씀"으로 읽는다 —
        // `sslRequired`가 non-Optional로 항상 기록되기 전에 만들어진 시크릿이 있다.
        case .database(let payload, let metadata):
            return .database(
                DatabaseFields(
                    linkString: payload.linkString,
                    isSSLRequired: metadata?.sslRequired ?? false
                )
            )

        case .sshKey(let payload, let metadata):
            return .sshKey(
                SSHKeyFields(
                    privateKey: payload.privateKey,
                    passphrase: payload.passphrase ?? "",
                    publicKey: metadata?.publicKey ?? "",
                    host: metadata?.host ?? "",
                    username: metadata?.username ?? ""
                )
            )

        // 도메인은 `privateKey`, 폼은 `sslPrivateKey` — SSH 필드명과 충돌해 폼에서만 개명돼 있다.
        case .sslTlsCertificate(let payload, let metadata):
            return .sslTlsCertificate(
                SSLCertFields(
                    certificate: payload.certificate,
                    sslPrivateKey: payload.privateKey,
                    certificateChain: payload.certificateChain ?? "",
                    renewCommand: metadata?.renewCommand ?? ""
                )
            )

        case .environmentVariableSet(let payload):
            return .envSet(EnvSetFields(envContent: payload.content))

        // licenseType은 String으로 저장돼 있어 폼 enum으로 되돌릴 때 실패할 수 있다
        // (앱이 tier 목록을 바꾼 뒤 이전 값이 남은 경우). 그때는 기본값으로 떨어뜨린다 —
        // 저장을 막을 만한 사유가 아니고, 사용자가 화면에서 다시 고를 수 있다.
        case .licenseKey(let payload, let metadata):
            return .licenseKey(
                LicenseKeyFields(
                    licenseKey: payload.licenseKey,
                    licenseTier: metadata?.licenseType.flatMap(LicenseTier.init(rawValue:)) ?? .individual,
                    registrationEmail: metadata?.registrationEmail ?? "",
                    orderNumber: metadata?.orderNumber ?? "",
                    website: metadata?.website ?? ""
                )
            )

        case .custom(let payload):
            return .custom(CustomFields(value: payload.value))
        }
    }
}
