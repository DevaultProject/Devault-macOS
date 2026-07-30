// Copyright © 2026 Devault. All rights reserved

import Foundation

/// PEM 헤더 카탈로그.
enum BuiltInPEMHeaders {
    /// 헤더 문자열 길이 내림차순. `-----BEGIN PRIVATE KEY-----` 같은 짧은 헤더가
    /// `-----BEGIN RSA PRIVATE KEY-----` 같은 긴 헤더보다 먼저 매칭돼 오탐하는 것을 막는다.
    static let all: [PEMHeaderRule] = [
        .init(header: "-----BEGIN PGP PRIVATE KEY BLOCK-----", keyType: "PGP", isCertificate: false),
        .init(header: "-----BEGIN OPENSSH PRIVATE KEY-----", keyType: "OpenSSH", isCertificate: false),
        .init(header: "-----BEGIN CERTIFICATE REQUEST-----", keyType: "CSR", isCertificate: true),
        .init(header: "-----BEGIN RSA PRIVATE KEY-----", keyType: "RSA", isCertificate: false),
        .init(header: "-----BEGIN DSA PRIVATE KEY-----", keyType: "DSA", isCertificate: false),
        .init(header: "-----BEGIN EC PRIVATE KEY-----", keyType: "EC", isCertificate: false),
        .init(header: "-----BEGIN CERTIFICATE-----", keyType: "X509", isCertificate: true),
        .init(header: "-----BEGIN PRIVATE KEY-----", keyType: "PKCS8", isCertificate: false),
    ]
}
