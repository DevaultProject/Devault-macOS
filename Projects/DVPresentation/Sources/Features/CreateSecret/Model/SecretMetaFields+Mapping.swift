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
    ///
    /// - Parameter baseline: 수정 저장에서 넘기는 원본 payload. metadata에는 폼이 입력받지 않는 필드가 섞여 있어
    ///   (`DatabaseMetadata.host`·`ServiceAccountMetadata.projectId` 등) 폼 값만으로 재조립하면 저장할 때마다
    ///   그 값들이 사라진다. 입력 경로가 있는 필드는 폼 값이 이기고, 없는 필드만 baseline에서 이어받는다.
    ///   생성 화면은 이어받을 원본이 없으므로 `nil`이다.
    func toCreateSecretPayload(
        secretType: CreatableSecretType,
        subType: CreatableSecretSubType?,
        preserving baseline: CreateSecretPayload? = nil
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
                f.serviceAccountMetadata(preserving: baseline?.serviceAccountMetadata)
            ))

        case .database(let f):
            return .success(.database(
                DatabasePayload(linkString: f.linkString),
                f.databaseMetadata(preserving: baseline?.databaseMetadata)
            ))

        case .sshKey(let f):
            return .success(.sshKey(
                SSHKeyPayload(privateKey: f.privateKey, passphrase: f.passphrase.nilIfEmpty),
                f.sshKeyMetadata(preserving: baseline?.sshKeyMetadata)
            ))

        case .sslTlsCertificate(let f):
            return .success(.sslTlsCertificate(
                SSLCertPayload(
                    certificate: f.certificate,
                    privateKey: f.sslPrivateKey,
                    certificateChain: f.certificateChain.nilIfEmpty
                ),
                f.sslCertMetadata(preserving: baseline?.sslCertMetadata)
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
    /// `expireDate`의 시:분:초를 그 날의 23:59:59로 고정하는 정규화는 `SecretUseCaseHelper.normalizedDraft`가 담당한다
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

// `preserving:`를 받는 것은 UI 입력 경로가 없는 필드를 가진 네 타입뿐이다.
// APIKey / OAuthClient / LicenseKey는 metadata의 모든 필드를 폼이 입력받으므로 이어받을 것이 없다.

private extension APIKeyTokenFields {
    /// authorityScope가 비어 있으면 `nil`. 도메인 필드명은 `APIKeyMetadata.scope`.
    var apiKeyMetadata: APIKeyMetadata? {
        authorityScope.nilIfEmpty.map { APIKeyMetadata(scope: $0) }
    }
}

private extension ServiceAccountFields {
    /// authority가 비어 있으면 `nil`. 단 `projectId` / `accountEmail`은 UI 입력 경로가 없어
    /// baseline에서 이어받는다 — 폼 값만으로 재조립하면 수정할 때마다 사라진다.
    /// 이어받은 값이 있으면 authority가 비어도 레코드를 남긴다.
    func serviceAccountMetadata(preserving baseline: ServiceAccountMetadata?) -> ServiceAccountMetadata? {
        let authority = authority.nilIfEmpty
        let projectId = baseline?.projectId
        let accountEmail = baseline?.accountEmail
        guard authority != nil || projectId != nil || accountEmail != nil else { return nil }
        return ServiceAccountMetadata(
            projectId: projectId,
            accountEmail: accountEmail,
            authority: authority
        )
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
    /// `keyType`은 UI 입력 경로가 없어 baseline에서 이어받는다.
    func sshKeyMetadata(preserving baseline: SSHKeyMetadata?) -> SSHKeyMetadata? {
        let pub = publicKey.nilIfEmpty
        let hst = host.nilIfEmpty
        let usr = username.nilIfEmpty
        let keyType = baseline?.keyType
        guard pub != nil || hst != nil || usr != nil || keyType != nil else { return nil }
        return SSHKeyMetadata(publicKey: pub, keyType: keyType, host: hst, username: usr)
    }
}

private extension DatabaseFields {
    /// `sslRequired`는 `false`도 유의미한 값이므로 항상 build한다.
    /// `nil`로 붕괴시키면 "SSL 안 씀"과 "미기록"이 구분되지 않고, 수정에서 SSL을 끄는 순간
    /// metadata 레코드가 통째로 사라져 아래 네 필드까지 함께 날아간다.
    /// (`licenseKeyMetadata`가 같은 이유로 이미 non-Optional이다.)
    ///
    /// `host` / `port` / `databaseName` / `username`은 UI 입력 경로가 없어 baseline에서 이어받는다.
    func databaseMetadata(preserving baseline: DatabaseMetadata?) -> DatabaseMetadata {
        DatabaseMetadata(
            host: baseline?.host,
            port: baseline?.port,
            databaseName: baseline?.databaseName,
            username: baseline?.username,
            sslRequired: isSSLRequired
        )
    }
}

private extension SSLCertFields {
    /// renewCommand가 비어 있으면 `nil`.
    /// `domain` / `issuer`는 UI 입력 경로가 없어 baseline에서 이어받는다 —
    /// 인증서 PEM에서 산출해 채우게 되면(별도 이슈) 그 값이 수정 저장에서 지워지면 안 된다.
    func sslCertMetadata(preserving baseline: SSLCertMetadata?) -> SSLCertMetadata? {
        let renewCommand = renewCommand.nilIfEmpty
        let domain = baseline?.domain
        let issuer = baseline?.issuer
        guard renewCommand != nil || domain != nil || issuer != nil else { return nil }
        return SSLCertMetadata(domain: domain, issuer: issuer, renewCommand: renewCommand)
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

// MARK: - Baseline metadata 추출

/// 보존 병합의 원본을 꺼낸다.
///
/// case가 어긋나면 `nil`을 돌려준다 — 수정 화면은 서브타입을 바꿀 수 없으므로(payload 스키마가 달라진다)
/// baseline과 편집 결과는 항상 같은 case다. 다른 case가 들어오는 것은 넘겨준 쪽의 버그이고,
/// 그때 남의 타입 metadata를 억지로 끼워 넣는 것보다 보존을 포기하는 편이 안전하다.
private extension CreateSecretPayload {

    var serviceAccountMetadata: ServiceAccountMetadata? {
        guard case .serviceAccount(_, let metadata) = self else { return nil }
        return metadata
    }

    var databaseMetadata: DatabaseMetadata? {
        guard case .database(_, let metadata) = self else { return nil }
        return metadata
    }

    var sshKeyMetadata: SSHKeyMetadata? {
        guard case .sshKey(_, let metadata) = self else { return nil }
        return metadata
    }

    var sslCertMetadata: SSLCertMetadata? {
        guard case .sslTlsCertificate(_, let metadata) = self else { return nil }
        return metadata
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
