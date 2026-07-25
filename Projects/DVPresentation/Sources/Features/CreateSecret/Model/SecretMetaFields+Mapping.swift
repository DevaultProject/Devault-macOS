// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation

extension SecretMetaFields {

    // MARK: - 필수 필드 판정 (단일 진실)

    /// 각 content case에서 누락된 모든 required 필드의 `FieldID` 목록.
    /// `isValid`와 `toCreateSecretPayload`가 공유하는 유일한 required 규칙 정의부 —
    /// 규칙 변경 시 이 프로퍼티만 수정하면 실시간 검증과 실제 저장 검증이 자동으로 정합된다.
    var missingRequiredFieldIDs: [FieldID] {
        switch content {
        case .apiKeyToken(let f):
            return f.value.isBlank ? [.value] : []
        case .oauthClient(let f):
            var missing: [FieldID] = []
            if f.clientId.isBlank { missing.append(.clientId) }
            if f.clientSecret.isBlank { missing.append(.clientSecret) }
            return missing
        case .serviceAccount(let f):
            return f.credentialJSON.isBlank ? [.credentialJSON] : []
        case .database(let f):
            return f.linkString.isBlank ? [.linkString] : []
        case .sshKey(let f):
            return f.privateKey.isBlank ? [.privateKey] : []
        case .sslTlsCertificate(let f):
            var missing: [FieldID] = []
            if f.certificate.isBlank { missing.append(.certificate) }
            if f.sslPrivateKey.isBlank { missing.append(.sslPrivateKey) }
            return missing
        case .envSet(let f):
            return f.envContent.isBlank ? [.envContent] : []
        case .licenseKey(let f):
            return f.licenseKey.isBlank ? [.licenseKey] : []
        case .custom(let f):
            return f.value.isBlank ? [.value] : []
        }
    }

    // MARK: - 도메인 매핑

    /// content case별로 payload + metadata를 조립. 필수 필드 누락 시 `.missingRequired`로 폼에 인라인 경고를 트리거.
    /// `apiKeyToken` case는 payload가 세 subType에 걸쳐 공유되므로 `subType` 인자로 CreateSecretPayload case를 최종 분기한다.
    func toCreateSecretPayload(
        secretType: CreatableSecretType,
        subType: CreatableSecretSubType?
    ) -> Result<CreateSecretPayload, FormError> {
        var missing: [FieldID] = []
        if name.isBlank { missing.append(.name) }
        missing.append(contentsOf: missingRequiredFieldIDs)
        if !missing.isEmpty {
            return .failure(.missingRequired(missing))
        }

        switch content {
        case .apiKeyToken(let f):
            let payload = APIKeyPayload(value: f.value)
            let meta = f.apiKeyMetadata
            switch subType {
            case .apiKey:        return .success(.apiKey(payload, meta))
            case .accessToken:   return .success(.accessToken(payload, meta))
            case .webhookSecret: return .success(.webhookSecret(payload, meta))
            default:             return .failure(.invalidTypeCombination)
            }

        case .oauthClient(let f):
            return .success(.oauthClient(
                OAuthClientPayload(clientId: f.clientId, clientSecret: f.clientSecret),
                f.oauthClientMetadata
            ))

        case .serviceAccount(let f):
            return .success(.serviceAccount(
                ServiceAccountPayload(credentialJSON: f.credentialJSON),
                f.serviceAccountMetadata
            ))

        case .database(let f):
            return .success(.database(
                DatabasePayload(linkString: f.linkString),
                f.databaseMetadata
            ))

        case .sshKey(let f):
            return .success(.sshKey(
                SSHKeyPayload(privateKey: f.privateKey, passphrase: f.passphrase.nilIfEmpty),
                f.sshKeyMetadata
            ))

        case .sslTlsCertificate(let f):
            return .success(.sslTlsCertificate(
                SSLCertPayload(
                    certificate: f.certificate,
                    privateKey: f.sslPrivateKey,
                    certificateChain: f.certificateChain.nilIfEmpty
                ),
                f.sslCertMetadata
            ))

        case .envSet(let f):
            return .success(.environmentVariableSet(EnvSetPayload(content: f.envContent)))

        case .licenseKey(let f):
            return .success(.licenseKey(
                LicenseKeyPayload(licenseKey: f.licenseKey),
                f.licenseKeyMetadata
            ))

        case .custom(let f):
            return .success(.custom(CustomPayload(value: f.value)))
        }
    }
    
    /// `SecretDraft`(공통 정보)로 매핑. `service`는 빈 문자열이면 `nil`로 대체, `environment`는 `rawValue`(String)로 저장.
    func toSecretDraft(
        secretType: CreatableSecretType,
        subType: CreatableSecretSubType?
    ) -> SecretDraft {
        SecretDraft(
            name: name,
            secretType: secretType.domainType,
            subType: subType?.domainSubType,
            service: service.nilIfEmpty,
            environment: environment.rawValue,
            expiresAt: expireDate,
            memo: memo.nilIfEmpty
        )
    }
}

// MARK: - Metadata builders (per sub-struct, nil-collapsing)

private extension APIKeyTokenFields {
    /// authorityScope가 비어 있으면 `nil`. 도메인 필드명은 `APIKeyMetadata.scope`.
    var apiKeyMetadata: APIKeyMetadata? {
        authorityScope.nilIfEmpty.map { APIKeyMetadata(scope: $0) }
    }
}

private extension ServiceAccountFields {
    /// authority가 비어 있으면 `nil`. projectId / accountEmail은 아직 UI 미노출로 항상 nil.
    var serviceAccountMetadata: ServiceAccountMetadata? {
        authority.nilIfEmpty.map { ServiceAccountMetadata(authority: $0) }
    }
}

private extension OAuthClientFields {
    /// redirectUri / scopes 하나라도 있으면 build, 아니면 `nil`.
    var oauthClientMetadata: OAuthClientMetadata? {
        let uri = redirectUri.nilIfEmpty
        let scopeList = scopes.nilIfEmpty
        guard uri != nil || scopeList != nil else { return nil }
        return OAuthClientMetadata(redirectUri: uri, scopes: scopeList)
    }
}

private extension SSHKeyFields {
    /// publicKey / host / username 하나라도 있으면 build, 아니면 `nil`.
    var sshKeyMetadata: SSHKeyMetadata? {
        let pub = publicKey.nilIfEmpty
        let hst = host.nilIfEmpty
        let usr = username.nilIfEmpty
        guard pub != nil || hst != nil || usr != nil else { return nil }
        return SSHKeyMetadata(publicKey: pub, keyType: nil, host: hst, username: usr)
    }
}

private extension DatabaseFields {
    /// 사용자가 명시적으로 SSL Required를 켰을 때만 metadata build.
    var databaseMetadata: DatabaseMetadata? {
        guard isSSLRequired else { return nil }
        return DatabaseMetadata(sslRequired: true)
    }
}

private extension SSLCertFields {
    /// renewCommand가 비어 있으면 `nil`.
    var sslCertMetadata: SSLCertMetadata? {
        renewCommand.nilIfEmpty.map { SSLCertMetadata(renewCommand: $0) }
    }
}

private extension LicenseKeyFields {
    /// `licenseTier`가 기본값을 항상 갖기 때문에 metadata는 항상 build된다.
    var licenseKeyMetadata: LicenseKeyMetadata {
        LicenseKeyMetadata(
            licenseType: licenseTier.rawValue,
            registrationEmail: registrationEmail.nilIfEmpty,
            orderNumber: orderNumber.nilIfEmpty,
            website: website.nilIfEmpty
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }

    /// 필수 필드 검증용 — whitespace만 있는 문자열도 미입력으로 처리.
    /// `isEmpty`와의 차이: `"   "`는 `isEmpty=false`지만 `isBlank=true`.
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
