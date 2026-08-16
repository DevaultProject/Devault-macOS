// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

import DVDomain
@testable import DVPresentation

/// 저장 시 **무엇을 다시 쓸지** 정하는 판정을 고정한다.
///
/// 잘못 판정하면 두 방향으로 틀린다 — 과소 판정이면 사용자가 고친 값이 저장되지 않고,
/// 과대 판정이면 바뀌지도 않은 payload가 재암호화되어 `keyTag`·`schemaVersion`이 갱신된다.
@Suite("CreateSecretPayload 변경 판정")
struct CreateSecretPayloadDiffTests {

    private static let baseline = CreateSecretPayload.apiKey(
        APIKeyPayload(value: "ghp_old"),
        APIKeyMetadata(scope: "repo:read")
    )

    // MARK: - 4분기

    @Test("변경 없음 → none")
    func noChange() {
        let change = Self.baseline.contentChange(comparedTo: Self.baseline)
        #expect(change == .none)
        #expect(change.content == nil, "쓸 것이 없으면 평문이 Client 경계를 넘지 않는다")
        #expect(change.writesPayload == false)
        #expect(change.writesMetadata == false)
        #expect(change.clearsMetadata == false)
    }

    @Test("payload만 변경 → payload")
    func payloadOnly() {
        let updated = CreateSecretPayload.apiKey(
            APIKeyPayload(value: "ghp_new"),
            APIKeyMetadata(scope: "repo:read")
        )

        let change = updated.contentChange(comparedTo: Self.baseline)

        #expect(change == .payload(updated))
        #expect(change.writesPayload)
        #expect(change.writesMetadata == false)
    }

    @Test("metadata만 변경 → metadata")
    func metadataOnly() {
        let updated = CreateSecretPayload.apiKey(
            APIKeyPayload(value: "ghp_old"),
            APIKeyMetadata(scope: "repo:write")
        )

        let change = updated.contentChange(comparedTo: Self.baseline)

        #expect(change == .metadata(updated))
        #expect(change.writesPayload == false)
        #expect(change.writesMetadata)
    }

    @Test("둘 다 변경 → payloadAndMetadata")
    func bothChanged() {
        let updated = CreateSecretPayload.apiKey(
            APIKeyPayload(value: "ghp_new"),
            APIKeyMetadata(scope: "repo:write")
        )

        let change = updated.contentChange(comparedTo: Self.baseline)

        #expect(change == .payloadAndMetadata(updated))
        #expect(change.writesPayload)
        #expect(change.writesMetadata)
    }

    // MARK: - metadata 삭제

    /// 마지막 남은 metadata 필드를 비우면 조립 결과가 nil이 된다. `none`으로 처리하면
    /// 지운 값이 저장소에 남아 다시 열 때 되살아난다.
    @Test("metadata가 비워짐 → metadataCleared")
    func metadataCleared() {
        let updated = CreateSecretPayload.apiKey(APIKeyPayload(value: "ghp_old"), nil)

        let change = updated.contentChange(comparedTo: Self.baseline)

        #expect(change == .metadataCleared)
        #expect(change.clearsMetadata)
        #expect(change.writesMetadata == false, "덮어쓰기와 삭제가 동시에 참이면 안 된다")
        #expect(change.content == nil)
    }

    @Test("payload 변경 + metadata 삭제 → payloadAndMetadataCleared")
    func payloadChangedAndMetadataCleared() {
        let updated = CreateSecretPayload.apiKey(APIKeyPayload(value: "ghp_new"), nil)

        let change = updated.contentChange(comparedTo: Self.baseline)

        #expect(change == .payloadAndMetadataCleared(updated))
        #expect(change.writesPayload)
        #expect(change.clearsMetadata)
        #expect(change.writesMetadata == false)
    }

    /// baseline에도 metadata가 없었으면 지울 것이 없다.
    @Test("원래 metadata가 없었으면 삭제로 보지 않는다")
    func absentMetadataIsNotAClear() {
        let baseline = CreateSecretPayload.apiKey(APIKeyPayload(value: "ghp_old"), nil)
        let updated = CreateSecretPayload.apiKey(APIKeyPayload(value: "ghp_new"), nil)

        let change = updated.contentChange(comparedTo: baseline)

        #expect(change == .payload(updated))
        #expect(change.clearsMetadata == false)
    }

    // MARK: - metadata 스키마가 없는 타입

    @Test("envSet은 metadata 스키마가 없어 payload 변경만 잡힌다")
    func envSetHasNoMetadata() {
        let baseline = CreateSecretPayload.environmentVariableSet(EnvSetPayload(content: "A=1"))
        let updated = CreateSecretPayload.environmentVariableSet(EnvSetPayload(content: "A=2"))

        let change = updated.contentChange(comparedTo: baseline)

        #expect(change == .payload(updated))
        #expect(change.writesMetadata == false)
        #expect(change.clearsMetadata == false)
    }

    @Test("custom도 값이 같으면 변경 없음이다")
    func customUnchanged() {
        let payload = CreateSecretPayload.custom(CustomPayload(value: "v"))

        #expect(payload.contentChange(comparedTo: payload) == .none)
    }

    // MARK: - 타입별 diff

    /// case마다 비교 대상을 손으로 적어야 해서, 한 곳만 빠뜨려도 그 타입의 변경이 조용히 무시된다.
    @Test("아홉 가지 content 조합 모두 payload 변경을 잡아낸다")
    func diffCatchesPayloadChangeInEveryCase() {
        let pairs: [(label: String, old: CreateSecretPayload, new: CreateSecretPayload)] = [
            ("apiKey",
             .apiKey(APIKeyPayload(value: "a"), nil), .apiKey(APIKeyPayload(value: "b"), nil)),
            ("accessToken",
             .accessToken(APIKeyPayload(value: "a"), nil), .accessToken(APIKeyPayload(value: "b"), nil)),
            ("webhookSecret",
             .webhookSecret(APIKeyPayload(value: "a"), nil), .webhookSecret(APIKeyPayload(value: "b"), nil)),
            ("oauthClient",
             .oauthClient(OAuthClientPayload(clientId: "i", clientSecret: "a"), nil),
             .oauthClient(OAuthClientPayload(clientId: "i", clientSecret: "b"), nil)),
            ("serviceAccount",
             .serviceAccount(ServiceAccountPayload(credentialJSON: "a"), nil),
             .serviceAccount(ServiceAccountPayload(credentialJSON: "b"), nil)),
            ("database",
             .database(DatabasePayload(linkString: "a"), nil), .database(DatabasePayload(linkString: "b"), nil)),
            ("sshKey",
             .sshKey(SSHKeyPayload(privateKey: "a", passphrase: nil), nil),
             .sshKey(SSHKeyPayload(privateKey: "b", passphrase: nil), nil)),
            ("sslTlsCertificate",
             .sslTlsCertificate(SSLCertPayload(certificate: "a", privateKey: "k", certificateChain: nil), nil),
             .sslTlsCertificate(SSLCertPayload(certificate: "b", privateKey: "k", certificateChain: nil), nil)),
            ("licenseKey",
             .licenseKey(LicenseKeyPayload(licenseKey: "a"), nil),
             .licenseKey(LicenseKeyPayload(licenseKey: "b"), nil)),
            ("envSet",
             .environmentVariableSet(EnvSetPayload(content: "a")),
             .environmentVariableSet(EnvSetPayload(content: "b"))),
            ("custom",
             .custom(CustomPayload(value: "a")), .custom(CustomPayload(value: "b"))),
        ]

        for pair in pairs {
            let result = CreateSecretPayload.diff(baseline: pair.old, updated: pair.new)
            #expect(result.payload, "\(pair.label): payload 변경을 잡아야 한다")
            #expect(result.metadata == false, "\(pair.label): metadata는 그대로다")
        }
    }
}
