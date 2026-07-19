// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation

extension SecretMetaFields {
    
    // MARK: - 실시간 UI 검증

    /// Create 버튼 disable/enable 판정용. `name` + 각 content case별 required 필드만 검사한다.
    func isValid(
        for type: CreatableSecretType,
        subType: CreatableSecretSubType?
    ) -> Bool {
        guard !name.isEmpty else { return false }
        switch content {
        case .apiKeyToken(let f):        return !f.value.isEmpty
        case .oauthClient(let f):        return !f.clientId.isEmpty && !f.clientSecret.isEmpty
        case .serviceAccount(let f):     return !f.credentialJSON.isEmpty
        case .database(let f):           return !f.linkString.isEmpty
        case .sshKey(let f):             return !f.privateKey.isEmpty
        case .sslTlsCertificate(let f):  return !f.certificate.isEmpty && !f.sslPrivateKey.isEmpty
        case .envSet(let f):             return !f.envContent.isEmpty
        case .licenseKey(let f):         return !f.licenseKey.isEmpty
        case .custom(let f):             return !f.value.isEmpty
        }
    }
    
    // MARK: - 도메인 매핑

    /// content case별로 payload + metadata를 조립. 필수 필드 누락 시 `.missingRequired`로 폼에 인라인 경고를 트리거.
    /// `apiKeyToken` case는 payload가 세 subType에 걸쳐 공유되므로 `subType` 인자로 CreateSecretPayload case를 최종 분기한다.
    func toCreateSecretPayload(
        secretType: CreatableSecretType,
        subType: CreatableSecretSubType?
    ) -> Result<CreateSecretPayload, FormError> {
        guard !name.isEmpty else {
            return .failure(.missingRequired(.name))
        }
        
        switch content {
        case .apiKeyToken(let f):
            guard !f.value.isEmpty else { return .failure(.missingRequired(.value)) }
            let payload = APIKeyPayload(value: f.value)
            let meta = f.apiKeyMetadata
            switch subType {
            case .apiKey:        return .success(.apiKey(payload, meta))
            case .accessToken:   return .success(.accessToken(payload, meta))
            case .webhookSecret: return .success(.webhookSecret(payload, meta))
            default:             return .failure(.invalidTypeCombination)
            }
            
        case .oauthClient(let f):
            guard !f.clientId.isEmpty else { return .failure(.missingRequired(.clientId)) }
            guard !f.clientSecret.isEmpty else { return .failure(.missingRequired(.clientSecret)) }
            return .success(.oauthClient(
                OAuthClientPayload(clientId: f.clientId, clientSecret: f.clientSecret),
                f.oauthClientMetadata
            ))
            
        case .serviceAccount(let f):
            guard !f.credentialJSON.isEmpty else { return .failure(.missingRequired(.credentialJSON)) }
            return .success(.serviceAccount(
                ServiceAccountPayload(credentialJSON: f.credentialJSON),
                nil
            ))
            
        case .database(let f):
            guard !f.linkString.isEmpty else { return .failure(.missingRequired(.linkString)) }
            return .success(.database(DatabasePayload(linkString: f.linkString), nil))
            
        case .sshKey(let f):
            guard !f.privateKey.isEmpty else { return .failure(.missingRequired(.privateKey)) }
            return .success(.sshKey(
                SSHKeyPayload(privateKey: f.privateKey, passphrase: f.passphrase.nilIfEmpty),
                f.sshKeyMetadata
            ))
            
        case .sslTlsCertificate(let f):
            guard !f.certificate.isEmpty else { return .failure(.missingRequired(.certificate)) }
            guard !f.sslPrivateKey.isEmpty else { return .failure(.missingRequired(.sslPrivateKey)) }
            return .success(.sslTlsCertificate(
                SSLCertPayload(
                    certificate: f.certificate,
                    privateKey: f.sslPrivateKey,
                    certificateChain: f.certificateChain.nilIfEmpty
                ),
                nil
            ))
            
        case .envSet(let f):
            guard !f.envContent.isEmpty else { return .failure(.missingRequired(.envContent)) }
            return .success(.environmentVariableSet(EnvSetPayload(content: f.envContent)))
            
        case .licenseKey(let f):
            guard !f.licenseKey.isEmpty else { return .failure(.missingRequired(.licenseKey)) }
            return .success(.licenseKey(
                LicenseKeyPayload(licenseKey: f.licenseKey),
                f.licenseKeyMetadata
            ))
            
        case .custom(let f):
            guard !f.value.isEmpty else { return .failure(.missingRequired(.value)) }
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
    /// scope가 비어 있으면 `nil`.
    var apiKeyMetadata: APIKeyMetadata? {
        scope.nilIfEmpty.map { APIKeyMetadata(scope: $0) }
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
}
