// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct PEMHeaderRule: Equatable, Sendable {
    /// 정확한 PEM 헤더 라인 (예: "-----BEGIN RSA PRIVATE KEY-----")
    public var header: String
    /// 메타데이터에 저장할 키 종류 (예: "RSA", "EC", "PKCS8", "OpenSSH", "PGP", "DSA", "X509", "CSR")
    public var keyType: String
    /// true면 metadata를 .certificate로, false면 .pemKey로 분기
    public var isCertificate: Bool

    public init(header: String, keyType: String, isCertificate: Bool) {
        self.header = header
        self.keyType = keyType
        self.isCertificate = isCertificate
    }
}
