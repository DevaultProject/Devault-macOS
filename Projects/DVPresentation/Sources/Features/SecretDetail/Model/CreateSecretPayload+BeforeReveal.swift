// Copyright © 2026 Devault. All rights reserved

import DVDomain

// MARK: - reveal 전 payload

/// reveal 하기 전에 조회 화면이 그릴 payload.
///
/// 진입 시 복호화하지 않기로 했지만 화면은 곧바로 그려져야 한다. 섹션 뷰는 payload를 필수로 받고,
/// 어느 섹션을 그릴지는 `(secretType, subType)`으로 정해지므로 타입에 맞는 껍데기가 필요하다.
///
/// **비는 것은 payload 쪽뿐이다.** 암호화되어 있어 복호화 전에는 값이 없고, 어차피 마스킹되므로
/// 빈 문자열이어도 화면이 달라지지 않는다. 반면 metadata는 평문이라 `Secret`을 손에 쥔 시점에
/// 이미 읽을 수 있으므로 여기서 채운다 — Host·Username·Scope·Redirect URL·Public Key·Renew Command가
/// 여기서 오고, 비워두면 비밀도 아닌 값을 보려고 인증을 받아야 한다.
extension CreateSecretPayload {

    static func beforeReveal(for secret: Secret) -> CreateSecretPayload {
        switch (secret.secretType, secret.subType) {
        case (.apiKeyToken, .accessToken):
            return .accessToken(APIKeyPayload(value: ""), secret.decodedMetadata(APIKeyMetadata.self))
        case (.apiKeyToken, .webhookSecret):
            return .webhookSecret(APIKeyPayload(value: ""), secret.decodedMetadata(APIKeyMetadata.self))
        case (.apiKeyToken, _):
            return .apiKey(APIKeyPayload(value: ""), secret.decodedMetadata(APIKeyMetadata.self))

        case (.oauth, .serviceAccount):
            return .serviceAccount(
                ServiceAccountPayload(credentialJSON: ""),
                secret.decodedMetadata(ServiceAccountMetadata.self)
            )
        case (.oauth, _):
            return .oauthClient(
                OAuthClientPayload(clientId: "", clientSecret: ""),
                secret.decodedMetadata(OAuthClientMetadata.self)
            )

        case (.database, _):
            return .database(DatabasePayload(linkString: ""), secret.decodedMetadata(DatabaseMetadata.self))

        case (.sshAndCredentials, .sslTlsCertificate):
            return .sslTlsCertificate(
                SSLCertPayload(certificate: "", privateKey: "", certificateChain: nil),
                secret.decodedMetadata(SSLCertMetadata.self)
            )
        case (.sshAndCredentials, _):
            return .sshKey(
                SSHKeyPayload(privateKey: "", passphrase: nil),
                secret.decodedMetadata(SSHKeyMetadata.self)
            )

        // envSet·custom은 metadata를 두지 않는 타입이라 payload 하나만 받는다.
        case (.environmentVariableSet, _):
            return .environmentVariableSet(EnvSetPayload(content: ""))

        case (.etc, .custom):
            return .custom(CustomPayload(value: ""))
        case (.etc, _):
            return .licenseKey(LicenseKeyPayload(licenseKey: ""), secret.decodedMetadata(LicenseKeyMetadata.self))
        }
    }
}
