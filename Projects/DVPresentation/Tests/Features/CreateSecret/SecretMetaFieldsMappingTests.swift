// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

import DVDomain
@testable import DVPresentation

/// 폼 → 도메인 매핑에서 **UI에 입력 경로가 없는 metadata 필드**가 살아남는지 검증한다.
///
/// 수정 저장은 폼 값으로 metadata를 재조립하므로, 이어받지 않으면 저장할 때마다 그 필드들이 사라진다.
/// 지금은 네 필드군에 값을 넣는 경로가 없어 실제로 잃을 값이 없지만, 값이 생기는 순간
/// (예: 인증서 PEM에서 domain·issuer 산출) 조용히 지우는 버그가 되므로 규칙을 먼저 고정한다.
@Suite("SecretMetaFields 도메인 매핑 — metadata 보존")
struct SecretMetaFieldsMappingTests {

    // MARK: - Database

    @Test("SSL Required를 꺼도 metadata가 nil로 붕괴하지 않는다")
    func databaseMetadataSurvivesSSLOff() throws {
        let fields = SecretMetaFields(
            content: .database(DatabaseFields(linkString: "postgres://db", isSSLRequired: false)),
            name: "DB"
        )

        let payload = try #require(mapped(fields, secretType: .database))

        guard case .database(_, let metadata) = payload else {
            Issue.record("database case여야 한다")
            return
        }
        // nil로 붕괴하면 "SSL 안 씀"과 "미기록"이 구분되지 않는다.
        #expect(metadata?.sslRequired == false)
    }

    @Test("database: baseline의 host·port·databaseName·username을 이어받는다")
    func databasePreservesUnexposedFields() throws {
        let baseline = CreateSecretPayload.database(
            DatabasePayload(linkString: "postgres://old"),
            DatabaseMetadata(
                host: "db.example.com",
                port: 5432,
                databaseName: "main",
                username: "admin",
                sslRequired: false
            )
        )
        let fields = SecretMetaFields(
            content: .database(DatabaseFields(linkString: "postgres://new", isSSLRequired: true)),
            name: "DB"
        )

        let payload = try #require(mapped(fields, secretType: .database, preserving: baseline))

        guard case .database(_, let metadata) = payload else {
            Issue.record("database case여야 한다")
            return
        }
        #expect(metadata?.host == "db.example.com")
        #expect(metadata?.port == 5432)
        #expect(metadata?.databaseName == "main")
        #expect(metadata?.username == "admin")
        // 입력 경로가 있는 필드는 폼 값이 이긴다.
        #expect(metadata?.sslRequired == true)
    }

    @Test("database: SSL 값은 baseline이 아니라 폼이 결정한다")
    func databaseSSLFollowsForm() throws {
        let baseline = CreateSecretPayload.database(
            DatabasePayload(linkString: "postgres://old"),
            DatabaseMetadata(sslRequired: true)
        )
        let fields = SecretMetaFields(
            content: .database(DatabaseFields(linkString: "postgres://new", isSSLRequired: false)),
            name: "DB"
        )

        let payload = try #require(mapped(fields, secretType: .database, preserving: baseline))

        guard case .database(_, let metadata) = payload else {
            Issue.record("database case여야 한다")
            return
        }
        #expect(metadata?.sslRequired == false)
    }

    // MARK: - ServiceAccount

    @Test("serviceAccount: baseline의 projectId·accountEmail을 이어받고 authority는 폼 값을 쓴다")
    func serviceAccountPreservesUnexposedFields() throws {
        let baseline = CreateSecretPayload.serviceAccount(
            ServiceAccountPayload(credentialJSON: "{}"),
            ServiceAccountMetadata(
                projectId: "devault-prod",
                accountEmail: "bot@devault.iam.gserviceaccount.com",
                authority: "old-authority"
            )
        )
        let fields = SecretMetaFields(
            content: .serviceAccount(
                ServiceAccountFields(credentialJSON: #"{"type":"service_account"}"#, authority: "new-authority")
            ),
            name: "SA"
        )

        let payload = try #require(
            mapped(fields, secretType: .oauth, subType: .serviceAccount, preserving: baseline)
        )

        guard case .serviceAccount(_, let metadata) = payload else {
            Issue.record("serviceAccount case여야 한다")
            return
        }
        #expect(metadata?.projectId == "devault-prod")
        #expect(metadata?.accountEmail == "bot@devault.iam.gserviceaccount.com")
        #expect(metadata?.authority == "new-authority")
    }

    @Test("serviceAccount: authority를 비워도 이어받을 값이 있으면 레코드를 남긴다")
    func serviceAccountKeepsRecordForPreservedFieldsOnly() throws {
        let baseline = CreateSecretPayload.serviceAccount(
            ServiceAccountPayload(credentialJSON: "{}"),
            ServiceAccountMetadata(projectId: "devault-prod")
        )
        let fields = SecretMetaFields(
            content: .serviceAccount(ServiceAccountFields(credentialJSON: "{}", authority: "")),
            name: "SA"
        )

        let payload = try #require(
            mapped(fields, secretType: .oauth, subType: .serviceAccount, preserving: baseline)
        )

        guard case .serviceAccount(_, let metadata) = payload else {
            Issue.record("serviceAccount case여야 한다")
            return
        }
        #expect(metadata?.projectId == "devault-prod")
        #expect(metadata?.authority == nil)
    }

    @Test("serviceAccount: 폼 값도 이어받을 값도 없으면 metadata는 nil이다")
    func serviceAccountCollapsesWhenNothingToKeep() throws {
        let fields = SecretMetaFields(
            content: .serviceAccount(ServiceAccountFields(credentialJSON: "{}", authority: "")),
            name: "SA"
        )

        let payload = try #require(mapped(fields, secretType: .oauth, subType: .serviceAccount))

        guard case .serviceAccount(_, let metadata) = payload else {
            Issue.record("serviceAccount case여야 한다")
            return
        }
        #expect(metadata == nil)
    }

    // MARK: - SSHKey

    @Test("sshKey: baseline의 keyType을 이어받는다")
    func sshKeyPreservesKeyType() throws {
        let baseline = CreateSecretPayload.sshKey(
            SSHKeyPayload(privateKey: "old", passphrase: nil),
            SSHKeyMetadata(publicKey: "ssh-rsa OLD", keyType: "ed25519", host: "old.host", username: "old")
        )
        let fields = SecretMetaFields(
            content: .sshKey(
                SSHKeyFields(
                    privateKey: "-----BEGIN OPENSSH PRIVATE KEY-----",
                    publicKey: "ssh-rsa NEW",
                    host: "new.host",
                    username: "deploy"
                )
            ),
            name: "SSH"
        )

        let payload = try #require(
            mapped(fields, secretType: .sshAndCredentials, subType: .sshKey, preserving: baseline)
        )

        guard case .sshKey(_, let metadata) = payload else {
            Issue.record("sshKey case여야 한다")
            return
        }
        #expect(metadata?.keyType == "ed25519")
        #expect(metadata?.publicKey == "ssh-rsa NEW")
        #expect(metadata?.host == "new.host")
        #expect(metadata?.username == "deploy")
    }

    @Test("sshKey: 폼 필드가 전부 비어도 baseline의 keyType만으로 레코드를 남긴다")
    func sshKeyKeepsRecordForKeyTypeOnly() throws {
        let baseline = CreateSecretPayload.sshKey(
            SSHKeyPayload(privateKey: "old", passphrase: nil),
            SSHKeyMetadata(keyType: "ed25519")
        )
        let fields = SecretMetaFields(
            content: .sshKey(SSHKeyFields(privateKey: "-----BEGIN OPENSSH PRIVATE KEY-----")),
            name: "SSH"
        )

        let payload = try #require(
            mapped(fields, secretType: .sshAndCredentials, subType: .sshKey, preserving: baseline)
        )

        guard case .sshKey(_, let metadata) = payload else {
            Issue.record("sshKey case여야 한다")
            return
        }
        #expect(metadata?.keyType == "ed25519")
    }

    // MARK: - SSL/TLS Certificate

    @Test("sslTlsCertificate: baseline의 domain·issuer를 이어받는다")
    func sslCertPreservesDomainAndIssuer() throws {
        let baseline = CreateSecretPayload.sslTlsCertificate(
            SSLCertPayload(certificate: "old", privateKey: "old", certificateChain: nil),
            SSLCertMetadata(domain: "devault.app", issuer: "Let's Encrypt", renewCommand: "old cmd")
        )
        let fields = SecretMetaFields(
            content: .sslTlsCertificate(
                SSLCertFields(
                    certificate: "-----BEGIN CERTIFICATE-----",
                    sslPrivateKey: "-----BEGIN PRIVATE KEY-----",
                    renewCommand: "certbot renew"
                )
            ),
            name: "TLS"
        )

        let payload = try #require(
            mapped(fields, secretType: .sshAndCredentials, subType: .sslTlsCertificate, preserving: baseline)
        )

        guard case .sslTlsCertificate(_, let metadata) = payload else {
            Issue.record("sslTlsCertificate case여야 한다")
            return
        }
        #expect(metadata?.domain == "devault.app")
        #expect(metadata?.issuer == "Let's Encrypt")
        #expect(metadata?.renewCommand == "certbot renew")
    }

    // MARK: - baseline 부재 · 불일치

    @Test("baseline이 없으면(생성 경로) 폼 값만으로 조립된다")
    func withoutBaselineNothingIsInherited() throws {
        let fields = SecretMetaFields(
            content: .sshKey(
                SSHKeyFields(privateKey: "-----BEGIN OPENSSH PRIVATE KEY-----", host: "host")
            ),
            name: "SSH"
        )

        let payload = try #require(mapped(fields, secretType: .sshAndCredentials, subType: .sshKey))

        guard case .sshKey(_, let metadata) = payload else {
            Issue.record("sshKey case여야 한다")
            return
        }
        #expect(metadata?.keyType == nil)
        #expect(metadata?.host == "host")
    }

    /// 서브타입은 수정 화면에서 바뀌지 않으므로 실제로는 일어나지 않는 조합이다.
    /// 그래도 남의 타입 metadata를 억지로 끼워 넣지 않는다는 것을 고정한다.
    @Test("baseline의 case가 다르면 이어받지 않는다")
    func mismatchedBaselineIsIgnored() throws {
        let baseline = CreateSecretPayload.apiKey(
            APIKeyPayload(value: "sk"),
            APIKeyMetadata(scope: "repo:read")
        )
        let fields = SecretMetaFields(
            content: .database(DatabaseFields(linkString: "postgres://db", isSSLRequired: true)),
            name: "DB"
        )

        let payload = try #require(mapped(fields, secretType: .database, preserving: baseline))

        guard case .database(_, let metadata) = payload else {
            Issue.record("database case여야 한다")
            return
        }
        #expect(metadata?.host == nil)
        #expect(metadata?.sslRequired == true)
    }

    // MARK: - Helpers

    /// 매핑 성공분만 꺼낸다. 실패(필수 필드 누락)는 이 Suite의 관심사가 아니므로 `nil`로 접는다.
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
