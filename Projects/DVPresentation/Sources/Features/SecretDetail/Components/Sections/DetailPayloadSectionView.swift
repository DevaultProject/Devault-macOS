// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// 복호화된 `CreateSecretPayload`를 타입별 조회 섹션으로 분기하는 디스패처.
///
/// `secret.secretType`/`subType`이 아니라 payload case로 분기한다 — 복호화 결과가
/// 실제로 어떤 스키마였는지가 렌더할 섹션을 결정한다. 메타 필드가 어긋난 레코드에서도
/// 화면과 값이 따로 놀지 않는다.
///
/// `default`를 두지 않는다. 도메인에 payload case가 추가되면 이 switch가 컴파일 에러로 잡아야
/// 새 타입이 조용히 빈 화면으로 떨어지지 않는다.
struct DetailPayloadSectionView: View {

    let secret: Secret
    let linkedProjects: [Project]
    let payload: CreateSecretPayload

    var body: some View {
        switch payload {
        // 3 서브타입이 같은 스키마를 공유하므로 섹션도 하나를 공유한다.
        case .apiKey(let apiKeyToken, let metadata),
             .accessToken(let apiKeyToken, let metadata),
             .webhookSecret(let apiKeyToken, let metadata):
            DetailAPIKeysTokenSectionView(
                secret: secret,
                linkedProjects: linkedProjects,
                payload: apiKeyToken,
                metadata: metadata
            )

        case .oauthClient(let oauthClient, let metadata):
            DetailOAuthClientSectionView(
                secret: secret,
                linkedProjects: linkedProjects,
                payload: oauthClient,
                metadata: metadata
            )

        case .serviceAccount(let serviceAccount, let metadata):
            DetailServiceAccountSectionView(
                secret: secret,
                linkedProjects: linkedProjects,
                payload: serviceAccount,
                metadata: metadata
            )

        case .database(let database, let metadata):
            DetailDatabaseSectionView(
                secret: secret,
                linkedProjects: linkedProjects,
                payload: database,
                metadata: metadata
            )

        case .sshKey(let sshKey, let metadata):
            DetailSSHKeySectionView(
                secret: secret,
                linkedProjects: linkedProjects,
                payload: sshKey,
                metadata: metadata
            )

        case .sslTlsCertificate(let sslCert, let metadata):
            DetailSSLTLSCertSectionView(
                secret: secret,
                linkedProjects: linkedProjects,
                payload: sslCert,
                metadata: metadata
            )

        case .environmentVariableSet(let envSet):
            DetailEnvSetSectionView(
                secret: secret,
                linkedProjects: linkedProjects,
                payload: envSet
            )

        case .licenseKey(let licenseKey, let metadata):
            DetailLicenseKeySectionView(
                secret: secret,
                linkedProjects: linkedProjects,
                payload: licenseKey,
                metadata: metadata
            )

        case .custom(let custom):
            DetailCustomSectionView(
                secret: secret,
                linkedProjects: linkedProjects,
                payload: custom
            )
        }
    }
}

// MARK: - Preview

#if DEBUG

/// `(secretType, subType)` → 프리뷰용 payload. `SecretClient.dummyClient().revealPayload`와 같은
/// 분기지만 async가 아니라 프리뷰에서 바로 값을 만들 수 있어야 해 별도로 둔다.
private func _previewPayload(for secret: Secret) -> CreateSecretPayload {
    switch (secret.secretType, secret.subType) {
    case (.apiKeyToken, .accessToken):
        return .accessToken(APIKeyPayload(value: "gho_accessToken"), APIKeyMetadata(scope: "user:email"))

    case (.apiKeyToken, .webhookSecret):
        return .webhookSecret(
            APIKeyPayload(value: "whsec_1234567890"),
            APIKeyMetadata(scope: "push, pull_request")
        )

    case (.apiKeyToken, _):
        return .apiKey(APIKeyPayload(value: "ghp_1234567890"), APIKeyMetadata(scope: "repo:read"))

    case (.oauth, .serviceAccount):
        return .serviceAccount(
            ServiceAccountPayload(credentialJSON: #"{"type": "service_account", "project_id": "devault"}"#),
            ServiceAccountMetadata(authority: "organization-admin")
        )

    case (.oauth, _):
        return .oauthClient(
            OAuthClientPayload(clientId: "preview_id", clientSecret: "preview_secret"),
            OAuthClientMetadata(redirectUri: "https://devault.app/oauth/callback", scopes: "openid, email")
        )

    case (.database, _):
        return .database(
            DatabasePayload(linkString: "postgresql://preview:5432/db"),
            DatabaseMetadata(sslRequired: true)
        )

    case (.sshAndCredentials, .sslTlsCertificate):
        return .sslTlsCertificate(
            SSLCertPayload(
                certificate: "-----BEGIN CERTIFICATE-----\npreview\n-----END CERTIFICATE-----",
                privateKey: "-----BEGIN PRIVATE KEY-----\npreview\n-----END PRIVATE KEY-----",
                certificateChain: nil
            ),
            SSLCertMetadata(renewCommand: "certbot renew")
        )

    case (.sshAndCredentials, _):
        return .sshKey(
            SSHKeyPayload(privateKey: "-----BEGIN OPENSSH PRIVATE KEY-----\npreview", passphrase: nil),
            SSHKeyMetadata(publicKey: "ssh-rsa AAAA preview", host: "deploy.internal", username: "deploy")
        )

    case (.environmentVariableSet, _):
        return .environmentVariableSet(EnvSetPayload(content: "KEY=value\nOTHER=123"))

    case (.etc, .custom):
        return .custom(CustomPayload(value: "preview_custom_value"))

    case (.etc, _):
        return .licenseKey(
            LicenseKeyPayload(licenseKey: "PREVIEW-LICENSE-1234"),
            LicenseKeyMetadata(
                licenseType: LicenseTier.team.rawValue,
                registrationEmail: "support@devault.app",
                orderNumber: "DV-2026-000123",
                website: "https://devault.app"
            )
        )
    }
}

/// 11개 `(secretType, subType)` 조합을 한 캔버스에서 훑는다 — 섹션마다 프리뷰를 열지 않고도
/// 공통 행 구성(Services 유무 · Expire Date 단독 · License Tier 치환)의 차이를 나란히 비교한다.
/// 각 섹션 최상단 Name 행이 어느 조합인지 알려준다(픽스처 이름에 서브타입이 들어있다).
#Preview("11 조합 sweep · matrix 전수 (420)") {
    ScrollView {
        VStack(alignment: .leading, spacing: 32) {
            ForEach([Secret].previewSubTypeMatrix, id: \.id) { secret in
                DetailPayloadSectionView(
                    secret: secret,
                    linkedProjects: [Project].preview,
                    payload: _previewPayload(for: secret)
                )

                Divider()
            }
        }
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
