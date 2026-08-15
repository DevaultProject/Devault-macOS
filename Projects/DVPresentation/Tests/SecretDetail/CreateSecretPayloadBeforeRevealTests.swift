// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

import DVDomain

@testable import DVPresentation

@Suite("CreateSecretPayload.beforeReveal")
struct CreateSecretPayloadBeforeRevealTests {

    // MARK: - Helpers

    private static func makeSecret(
        secretType: SecretType,
        subType: SecretSubType? = nil,
        metadata: (any SecretMetadataContent)? = nil
    ) -> Secret {
        Secret(
            id: UUID(),
            name: "Test Secret",
            secretType: secretType,
            subType: subType,
            createdAt: Date(),
            updatedAt: Date(),
            payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1),
            metadata: metadata.map {
                SecretMetadata(
                    metadataJSON: try! JSONEncoder().encode($0),
                    schemaVersion: type(of: $0).schemaVersion
                )
            }
        )
    }

    // MARK: - metadata는 복호화 없이 채워진다

    /// 이 화면의 핵심 전제 — metadata는 평문이라 reveal 전에도 읽을 수 있다.
    /// 비워두면 비밀도 아닌 Redirect URL을 보려고 인증을 받아야 한다.
    @Test("oauthClient: metadata가 그대로 채워진다")
    func oauthClient_fillsMetadata() {
        let secret = Self.makeSecret(
            secretType: .oauth,
            subType: .oauthClient,
            metadata: OAuthClientMetadata(
                redirectUri: "https://app.example/oauth/callback",
                scopes: "openid, profile"
            )
        )

        guard case .oauthClient(let payload, let metadata) = CreateSecretPayload.beforeReveal(for: secret) else {
            Issue.record("oauthClient 케이스가 나와야 한다")
            return
        }

        #expect(metadata?.redirectUri == "https://app.example/oauth/callback")
        #expect(metadata?.scopes == "openid, profile")
        // 암호화된 쪽은 비어 있어야 한다 — 마스킹되므로 화면은 달라지지 않는다.
        #expect(payload.clientId.isEmpty)
        #expect(payload.clientSecret.isEmpty)
    }

    @Test("sshKey: Public Key·Host·Username이 채워진다")
    func sshKey_fillsMetadata() {
        let secret = Self.makeSecret(
            secretType: .sshAndCredentials,
            subType: .sshKey,
            metadata: SSHKeyMetadata(
                publicKey: "ssh-rsa AAAAB3 deploy@example",
                host: "deploy.internal",
                username: "deploy"
            )
        )

        guard case .sshKey(let payload, let metadata) = CreateSecretPayload.beforeReveal(for: secret) else {
            Issue.record("sshKey 케이스가 나와야 한다")
            return
        }

        #expect(metadata?.publicKey == "ssh-rsa AAAAB3 deploy@example")
        #expect(metadata?.host == "deploy.internal")
        #expect(metadata?.username == "deploy")
        #expect(payload.privateKey.isEmpty)
        #expect(payload.passphrase == nil)
    }

    @Test("sslTlsCertificate: Renew Command가 채워진다")
    func sslCert_fillsMetadata() {
        let secret = Self.makeSecret(
            secretType: .sshAndCredentials,
            subType: .sslTlsCertificate,
            metadata: SSLCertMetadata(renewCommand: "certbot renew --cert-name devault.app")
        )

        guard case .sslTlsCertificate(_, let metadata) = CreateSecretPayload.beforeReveal(for: secret) else {
            Issue.record("sslTlsCertificate 케이스가 나와야 한다")
            return
        }

        #expect(metadata?.renewCommand == "certbot renew --cert-name devault.app")
    }

    // MARK: - metadata가 없는 경우

    @Test("metadata가 nil이면 nil로 남는다")
    func noMetadata_staysNil() {
        let secret = Self.makeSecret(secretType: .oauth, subType: .oauthClient)

        guard case .oauthClient(_, let metadata) = CreateSecretPayload.beforeReveal(for: secret) else {
            Issue.record("oauthClient 케이스가 나와야 한다")
            return
        }

        #expect(metadata == nil)
    }

    /// 스키마가 어긋나도 시크릿 자체는 열려야 한다 — 해당 필드만 빈다.
    @Test("metadata JSON이 깨져 있어도 nil로 삼키고 케이스는 유지한다")
    func brokenMetadata_decodesToNil() {
        var secret = Self.makeSecret(secretType: .oauth, subType: .oauthClient)
        secret.metadata = SecretMetadata(
            metadataJSON: Data("not json".utf8),
            schemaVersion: 1
        )

        guard case .oauthClient(_, let metadata) = CreateSecretPayload.beforeReveal(for: secret) else {
            Issue.record("oauthClient 케이스가 나와야 한다")
            return
        }

        #expect(metadata == nil)
    }

    // MARK: - metadata를 두지 않는 타입

    @Test("envSet은 metadata 없이 payload만 그린다")
    func envSet_hasNoMetadata() {
        let secret = Self.makeSecret(secretType: .environmentVariableSet)

        guard case .environmentVariableSet(let payload) = CreateSecretPayload.beforeReveal(for: secret) else {
            Issue.record("environmentVariableSet 케이스가 나와야 한다")
            return
        }

        #expect(payload.content.isEmpty)
    }
}
