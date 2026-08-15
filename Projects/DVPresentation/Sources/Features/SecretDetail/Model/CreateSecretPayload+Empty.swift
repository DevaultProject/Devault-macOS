// Copyright © 2026 Devault. All rights reserved

import DVDomain

// MARK: - 복호화 전 자리채움 payload

/// 값이 아직 없을 때 조회 화면이 그릴 빈 payload.
///
/// 진입 시 복호화하지 않기로 했지만 화면은 곧바로 그려져야 한다. 섹션 뷰는 payload를 필수로 받고,
/// 어느 섹션을 그릴지는 `(secretType, subType)`으로 정해지므로 **타입에 맞는 빈 껍데기**만 있으면 된다.
///
/// 민감 필드는 어차피 마스킹되어 값이 화면에 나오지 않으므로 빈 문자열이어도 표시가 달라지지 않는다.
/// metadata는 nil로 둔다 — 평문 필드는 `Secret`이 직접 들고 있어 이 자리채움과 무관하다.
extension CreateSecretPayload {

    static func empty(for secret: Secret) -> CreateSecretPayload {
        switch (secret.secretType, secret.subType) {
        case (.apiKeyToken, .accessToken):
            return .accessToken(APIKeyPayload(value: ""), nil)
        case (.apiKeyToken, .webhookSecret):
            return .webhookSecret(APIKeyPayload(value: ""), nil)
        case (.apiKeyToken, _):
            return .apiKey(APIKeyPayload(value: ""), nil)

        case (.oauth, .serviceAccount):
            return .serviceAccount(ServiceAccountPayload(credentialJSON: ""), nil)
        case (.oauth, _):
            return .oauthClient(OAuthClientPayload(clientId: "", clientSecret: ""), nil)

        case (.database, _):
            return .database(DatabasePayload(linkString: ""), nil)

        case (.sshAndCredentials, .sslTlsCertificate):
            return .sslTlsCertificate(
                SSLCertPayload(certificate: "", privateKey: "", certificateChain: nil),
                nil
            )
        case (.sshAndCredentials, _):
            return .sshKey(SSHKeyPayload(privateKey: "", passphrase: nil), nil)

        case (.environmentVariableSet, _):
            return .environmentVariableSet(EnvSetPayload(content: ""))

        case (.etc, .custom):
            return .custom(CustomPayload(value: ""))
        case (.etc, _):
            return .licenseKey(LicenseKeyPayload(licenseKey: ""), nil)
        }
    }
}
