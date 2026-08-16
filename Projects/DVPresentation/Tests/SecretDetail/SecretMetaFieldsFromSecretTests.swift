// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

import DVDomain
@testable import DVPresentation

/// 수정 화면 진입에 쓰는 역매핑을 검증한다.
///
/// 정방향(`toCreateSecretPayload`)과 역방향(`contentFields`)이 어긋나면 수정 화면을 열었다 그대로
/// 저장하는 것만으로 값이 바뀐다. 두 방향은 서로를 되감아야 하므로 **라운드트립**으로 고정한다.
@Suite("SecretMetaFields 역매핑")
struct SecretMetaFieldsFromSecretTests {

    // MARK: - 라운드트립

    @Test("모든 조합에서 폼 → payload → 폼 → payload가 같은 값으로 돌아온다")
    func roundTripAcrossAllCombinations() throws {
        for combination in Combination.filled + Combination.minimal {
            let fields = combination.makeFields()

            let first = try #require(
                mapped(fields, secretType: combination.secretType, subType: combination.subType),
                "\(combination.label): 정방향 매핑이 성공해야 한다"
            )

            var reversed = fields
            reversed.content = first.contentFields

            // 폼 필드 자체가 복원되는지 — payload만 같고 폼이 달라지면 화면에 다른 값이 뜬다.
            #expect(reversed.content == fields.content, "\(combination.label): content 복원")

            let second = try #require(
                mapped(reversed, secretType: combination.secretType, subType: combination.subType),
                "\(combination.label): 역방향 결과의 재매핑이 성공해야 한다"
            )
            #expect(first == second, "\(combination.label): payload 복원")
        }
    }

    @Test("apiKeyToken 세 서브타입은 같은 폼 필드로 접히고 서브타입은 payload case가 결정한다")
    func apiKeyTokenSubTypesShareContentFields() throws {
        let fields = SecretMetaFields(
            content: .apiKeyToken(APIKeyTokenFields(value: "ghp_x", authorityScope: "repo:read")),
            name: "Token"
        )

        let apiKey = try #require(mapped(fields, secretType: .apiKeyToken, subType: .apiKey))
        let accessToken = try #require(mapped(fields, secretType: .apiKeyToken, subType: .accessToken))
        let webhook = try #require(mapped(fields, secretType: .apiKeyToken, subType: .webhookSecret))

        // payload case는 다르지만
        #expect(apiKey != accessToken)
        #expect(accessToken != webhook)
        // 되돌린 폼 필드는 셋 다 같다
        #expect(apiKey.contentFields == accessToken.contentFields)
        #expect(accessToken.contentFields == webhook.contentFields)
    }

    @Test("metadata가 없는 payload는 폼의 해당 필드가 빈 문자열이 된다")
    func missingMetadataBecomesEmptyStrings() {
        let payload = CreateSecretPayload.sshKey(
            SSHKeyPayload(privateKey: "pk", passphrase: nil),
            nil
        )

        guard case .sshKey(let f) = payload.contentFields else {
            Issue.record("sshKey case여야 한다")
            return
        }
        #expect(f.privateKey == "pk")
        #expect(f.passphrase == "")
        #expect(f.publicKey == "")
        #expect(f.host == "")
        #expect(f.username == "")
    }

    @Test("database metadata가 없으면 SSL Required는 꺼진 것으로 읽는다")
    func missingDatabaseMetadataMeansSSLOff() {
        let payload = CreateSecretPayload.database(DatabasePayload(linkString: "postgres://x"), nil)

        guard case .database(let f) = payload.contentFields else {
            Issue.record("database case여야 한다")
            return
        }
        #expect(f.isSSLRequired == false)
    }

    @Test("알 수 없는 licenseType은 기본 tier로 떨어진다")
    func unknownLicenseTypeFallsBackToDefault() {
        let payload = CreateSecretPayload.licenseKey(
            LicenseKeyPayload(licenseKey: "AAAA"),
            LicenseKeyMetadata(licenseType: "platinum")
        )

        guard case .licenseKey(let f) = payload.contentFields else {
            Issue.record("licenseKey case여야 한다")
            return
        }
        #expect(f.licenseTier == .individual)
    }

    // MARK: - init(secret:payload:projectIds:)

    @Test("Secret의 공통 필드가 폼 초기값으로 옮겨진다")
    func initMapsCommonFields() throws {
        let expiresAt = Date(timeIntervalSince1970: 1_800_000_000)
        let projectIds = [UUID(), UUID()]
        let secret = makeSecret(
            name: "GitHub Token",
            service: "GitHub",
            environment: "prod",
            expiresAt: expiresAt,
            memo: "배포용"
        )

        let fields = SecretMetaFields(
            secret: secret,
            payload: .apiKey(APIKeyPayload(value: "ghp_x"), APIKeyMetadata(scope: "repo:read")),
            projectIds: projectIds
        )

        #expect(fields.name == "GitHub Token")
        #expect(fields.service == "GitHub")
        #expect(fields.environment == .prod)
        // 도메인 expiresAt → 폼 expireDate
        #expect(fields.expireDate == expiresAt)
        #expect(fields.memo == "배포용")
        #expect(fields.projectIds == projectIds)
        #expect(fields.content == .apiKeyToken(APIKeyTokenFields(value: "ghp_x", authorityScope: "repo:read")))
    }

    @Test("Secret의 optional 필드가 nil이면 폼에서는 빈 문자열이 된다")
    func initMapsNilOptionalsToEmptyStrings() {
        let secret = makeSecret(name: "Bare", service: nil, environment: nil, expiresAt: nil, memo: nil)

        let fields = SecretMetaFields(
            secret: secret,
            payload: .custom(CustomPayload(value: "v")),
            projectIds: []
        )

        #expect(fields.service == "")
        #expect(fields.memo == "")
        #expect(fields.expireDate == nil)
        #expect(fields.projectIds.isEmpty)
    }

    @Test("알 수 없는 environment 문자열은 기본값으로 떨어진다")
    func initFallsBackForUnknownEnvironment() {
        let secret = makeSecret(name: "X", service: nil, environment: "canary", expiresAt: nil, memo: nil)

        let fields = SecretMetaFields(
            secret: secret,
            payload: .custom(CustomPayload(value: "v")),
            projectIds: []
        )

        #expect(fields.environment == .dev)
    }

    @Test("폼 초기값을 그대로 저장하면 원본과 같은 payload가 나온다")
    func initThenSaveReproducesPayload() throws {
        let payload = CreateSecretPayload.sslTlsCertificate(
            SSLCertPayload(
                certificate: "-----BEGIN CERTIFICATE-----",
                privateKey: "-----BEGIN PRIVATE KEY-----",
                certificateChain: "-----BEGIN CERTIFICATE-----chain"
            ),
            SSLCertMetadata(renewCommand: "certbot renew")
        )
        let secret = makeSecret(
            name: "TLS",
            secretType: .sshAndCredentials,
            subType: .sslTlsCertificate,
            service: nil,
            environment: nil,
            expiresAt: nil,
            memo: nil
        )

        let fields = SecretMetaFields(secret: secret, payload: payload, projectIds: [])
        let remapped = try #require(
            mapped(fields, secretType: .sshAndCredentials, subType: .sslTlsCertificate, preserving: payload)
        )

        #expect(remapped == payload)
    }

    // MARK: - Fixtures

    private struct Combination {
        let label: String
        let secretType: CreatableSecretType
        let subType: CreatableSecretSubType?
        let content: SecretContentFields

        func makeFields() -> SecretMetaFields {
            SecretMetaFields(content: content, name: "Fixture")
        }

        /// optional 필드까지 모두 채운 경우.
        static let filled: [Combination] = [
            .init(label: "apiKey", secretType: .apiKeyToken, subType: .apiKey,
                  content: .apiKeyToken(APIKeyTokenFields(value: "ghp_1", authorityScope: "repo:read"))),
            .init(label: "accessToken", secretType: .apiKeyToken, subType: .accessToken,
                  content: .apiKeyToken(APIKeyTokenFields(value: "ghp_2", authorityScope: "user:email"))),
            .init(label: "webhookSecret", secretType: .apiKeyToken, subType: .webhookSecret,
                  content: .apiKeyToken(APIKeyTokenFields(value: "whsec_3", authorityScope: "push"))),
            .init(label: "oauthClient", secretType: .oauth, subType: .oauthClient,
                  content: .oauthClient(OAuthClientFields(
                      clientId: "Iv1.abc",
                      clientSecret: "ghs_secret",
                      redirectUri: "https://app.example/callback",
                      scopes: "read:user, write:issue"
                  ))),
            .init(label: "serviceAccount", secretType: .oauth, subType: .serviceAccount,
                  content: .serviceAccount(ServiceAccountFields(
                      credentialJSON: #"{"type":"service_account"}"#,
                      authority: "organization-admin"
                  ))),
            .init(label: "database", secretType: .database, subType: nil,
                  content: .database(DatabaseFields(linkString: "postgres://u:p@h:5432/db", isSSLRequired: true))),
            .init(label: "sshKey", secretType: .sshAndCredentials, subType: .sshKey,
                  content: .sshKey(SSHKeyFields(
                      privateKey: "-----BEGIN OPENSSH PRIVATE KEY-----",
                      passphrase: "secret-phrase",
                      publicKey: "ssh-rsa AAAA",
                      host: "bastion.example.com",
                      username: "ubuntu"
                  ))),
            .init(label: "sslTlsCertificate", secretType: .sshAndCredentials, subType: .sslTlsCertificate,
                  content: .sslTlsCertificate(SSLCertFields(
                      certificate: "-----BEGIN CERTIFICATE-----",
                      sslPrivateKey: "-----BEGIN PRIVATE KEY-----",
                      certificateChain: "-----BEGIN CERTIFICATE-----chain",
                      renewCommand: "certbot renew --cert-name example.com"
                  ))),
            .init(label: "envSet", secretType: .environmentVariableSet, subType: nil,
                  content: .envSet(EnvSetFields(envContent: "DATABASE_URL=postgres://x\nSECRET_KEY=abc"))),
            .init(label: "licenseKey", secretType: .etc, subType: .licenseKey,
                  content: .licenseKey(LicenseKeyFields(
                      licenseKey: "AAAA-BBBB",
                      licenseTier: .team,
                      registrationEmail: "team@example.com",
                      orderNumber: "ORD-42",
                      website: "https://jetbrains.com"
                  ))),
            .init(label: "custom", secretType: .etc, subType: .custom,
                  content: .custom(CustomFields(value: "legacy-value"))),
        ]

        /// 필수 필드만 채운 경우. optional이 `nil`로 접혔다가 `""`로 돌아오는 경로를 훑는다.
        static let minimal: [Combination] = [
            .init(label: "apiKey(최소)", secretType: .apiKeyToken, subType: .apiKey,
                  content: .apiKeyToken(APIKeyTokenFields(value: "v"))),
            .init(label: "accessToken(최소)", secretType: .apiKeyToken, subType: .accessToken,
                  content: .apiKeyToken(APIKeyTokenFields(value: "v"))),
            .init(label: "webhookSecret(최소)", secretType: .apiKeyToken, subType: .webhookSecret,
                  content: .apiKeyToken(APIKeyTokenFields(value: "v"))),
            .init(label: "oauthClient(최소)", secretType: .oauth, subType: .oauthClient,
                  content: .oauthClient(OAuthClientFields(clientId: "i", clientSecret: "s"))),
            .init(label: "serviceAccount(최소)", secretType: .oauth, subType: .serviceAccount,
                  content: .serviceAccount(ServiceAccountFields(credentialJSON: "{}"))),
            .init(label: "database(최소)", secretType: .database, subType: nil,
                  content: .database(DatabaseFields(linkString: "postgres://x"))),
            .init(label: "sshKey(최소)", secretType: .sshAndCredentials, subType: .sshKey,
                  content: .sshKey(SSHKeyFields(privateKey: "pk"))),
            .init(label: "sslTlsCertificate(최소)", secretType: .sshAndCredentials, subType: .sslTlsCertificate,
                  content: .sslTlsCertificate(SSLCertFields(certificate: "c", sslPrivateKey: "k"))),
            .init(label: "envSet(최소)", secretType: .environmentVariableSet, subType: nil,
                  content: .envSet(EnvSetFields(envContent: "A=1"))),
            .init(label: "licenseKey(최소)", secretType: .etc, subType: .licenseKey,
                  content: .licenseKey(LicenseKeyFields(licenseKey: "L"))),
            .init(label: "custom(최소)", secretType: .etc, subType: .custom,
                  content: .custom(CustomFields(value: "v"))),
        ]
    }

    private func makeSecret(
        name: String,
        secretType: SecretType = .apiKeyToken,
        subType: SecretSubType? = .apiKey,
        service: String?,
        environment: String?,
        expiresAt: Date?,
        memo: String?
    ) -> Secret {
        Secret(
            id: UUID(),
            name: name,
            secretType: secretType,
            subType: subType,
            service: service,
            environment: environment,
            expiresAt: expiresAt,
            memo: memo,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
        )
    }

    private func mapped(
        _ fields: SecretMetaFields,
        secretType: CreatableSecretType,
        subType: CreatableSecretSubType? = nil,
        preserving baseline: CreateSecretPayload? = nil
    ) -> CreateSecretPayload? {
        guard case .success(let payload) = fields.toCreateSecretPayload(
            secretType: secretType,
            subType: subType,
            preserving: baseline
        ) else {
            return nil
        }
        return payload
    }
}
