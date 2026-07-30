// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 감지된 값에서 추가로 파싱해낸 부가 메타데이터. Form auto-fill · 추가 힌트 UI에 사용.
public enum DetectedMetadata: Equatable, Sendable {
    /// JWT header/payload에서 파싱한 claim 정보.
    case jwt(JWTInfo)
    /// 데이터베이스 접속 URL에서 파싱한 host/port/db 이름.
    case database(DatabaseInfo)
    /// PEM 프라이빗 키 헤더에서 파악한 키 종류.
    case pemKey(PEMKeyInfo)
    /// X509 · CSR 인증서. 실제 subject 파싱은 후속 확장.
    case certificate(CertificateInfo)
    /// 여러 줄 KEY=VALUE 세트에서 추출한 KEY 이름 목록.
    case envSet(keys: [String])
    /// GCP · Firebase · OAuth client · AWS 등 JSON credential 문서.
    case json(JSONCredentialInfo)

    public struct JWTInfo: Equatable, Sendable {
        /// JWT header의 `alg` claim (예: "HS256", "RS256").
        public var algorithm: String?
        /// JWT payload의 `iss` claim.
        public var issuer: String?
        /// JWT payload의 `sub` claim.
        public var subject: String?
        /// JWT payload의 `exp` claim을 Date로 변환한 값.
        public var expiresAt: Date?

        public init(
            algorithm: String? = nil,
            issuer: String? = nil,
            subject: String? = nil,
            expiresAt: Date? = nil
        ) {
            self.algorithm = algorithm
            self.issuer = issuer
            self.subject = subject
            self.expiresAt = expiresAt
        }
    }

    public struct DatabaseInfo: Equatable, Sendable {
        /// 접속 URL의 scheme (예: "postgres", "mongodb+srv").
        public var scheme: String
        /// 호스트명.
        public var host: String?
        /// 포트. URL에 명시가 없으면 scheme 기본값으로 채워질 수 있다.
        public var port: Int?
        /// URL path에서 추출한 database 이름.
        public var databaseName: String?
        /// URL user info 부분.
        public var username: String?

        public init(
            scheme: String,
            host: String? = nil,
            port: Int? = nil,
            databaseName: String? = nil,
            username: String? = nil
        ) {
            self.scheme = scheme
            self.host = host
            self.port = port
            self.databaseName = databaseName
            self.username = username
        }
    }

    public struct PEMKeyInfo: Equatable, Sendable {
        /// PEM 헤더에서 파악한 키 종류. "RSA" · "EC" · "PKCS8" · "OpenSSH" · "PGP" · "DSA" 중 하나.
        public var keyType: String
        /// OpenSSH 키 등 본문에서 추가로 파싱한 알고리즘 이름 (예: "ed25519").
        public var algorithm: String?

        public init(keyType: String, algorithm: String? = nil) {
            self.keyType = keyType
            self.algorithm = algorithm
        }
    }

    public struct CertificateInfo: Equatable, Sendable {
        /// 인증서 subject의 CN(Common Name) 등 도메인.
        public var subjectDomain: String?
        /// 인증서 발급자.
        public var issuer: String?
        /// 인증서 만료 시각.
        public var notAfter: Date?

        public init(
            subjectDomain: String? = nil,
            issuer: String? = nil,
            notAfter: Date? = nil
        ) {
            self.subjectDomain = subjectDomain
            self.issuer = issuer
            self.notAfter = notAfter
        }
    }

    public struct JSONCredentialInfo: Equatable, Sendable {
        /// JSON 문서의 세부 종류.
        public var kind: Kind
        /// GCP · Firebase의 `project_id`.
        public var projectId: String?
        /// GCP · Firebase의 `client_email`.
        public var clientEmail: String?
        /// OAuth client 등의 `client_id`.
        public var clientId: String?
        /// OAuth client의 `redirect_uris` 배열.
        public var redirectUris: [String]

        public init(
            kind: Kind,
            projectId: String? = nil,
            clientEmail: String? = nil,
            clientId: String? = nil,
            redirectUris: [String] = []
        ) {
            self.kind = kind
            self.projectId = projectId
            self.clientEmail = clientEmail
            self.clientId = clientId
            self.redirectUris = redirectUris
        }

        public enum Kind: String, Equatable, Sendable {
            case gcpServiceAccount
            case firebaseServiceAccount
            case googleOAuthClient
            case awsCredentials
            case generic
        }
    }
}
