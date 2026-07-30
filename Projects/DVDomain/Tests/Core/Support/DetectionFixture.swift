// Copyright © 2026 Devault. All rights reserved

import Foundation

@testable import DVDomain

enum DetectionFixture {
    /// 실 서비스 토큰 금지. Prefix만 진짜, 뒤는 반복 문자열.
    static func openAIToken(length: Int = 51) -> String {
        "sk-" + String(repeating: "a", count: max(0, length - 3))
    }

    static func anthropicToken(length: Int = 40) -> String {
        "sk-ant-" + String(repeating: "b", count: max(0, length - 7))
    }

    static func stabilityToken(length: Int = 51) -> String {
        "sk-xxxx-stabilityxxxx" + String(repeating: "s", count: max(0, length - 21))
    }

    static let pemRSA = """
        -----BEGIN RSA PRIVATE KEY-----
        MIIEpAIBAAKC
        -----END RSA PRIVATE KEY-----
        """

    /// 감지 로직이 raw substring `ed25519`만 검사하므로 실제 OpenSSH key(base64 body에는 리터럴 없음) 대신
    /// 헤더 · 디스크립터에 알고리즘 이름이 노출된 형태의 fixture를 사용한다.
    static let pemOpenSSHEd25519 = """
        -----BEGIN OPENSSH PRIVATE KEY-----
        Comment: ssh-ed25519 test key
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAA
        -----END OPENSSH PRIVATE KEY-----
        """

    static let pemCertificate = """
        -----BEGIN CERTIFICATE-----
        MIIDazCCAlOgAwIBAgIU
        -----END CERTIFICATE-----
        """

    static let postgresURL = "postgres://user:pw@host.example.com:5432/mydb"
    static let neonURL = "postgres://user:pw@ep-cool-name.neon.tech/neondb"
    static let mongoSRV = "mongodb+srv://user:pw@cluster0.abc.mongodb.net/prod"

    /// header/payload를 JSON → base64URL 인코딩해 서명 파트를 임의 문자열로 붙인 fake JWT.
    static func jwt(
        header: [String: Any] = ["alg": "HS256", "typ": "JWT"],
        payload: [String: Any],
        signature: String = "sig"
    ) -> String {
        let hd = try! JSONSerialization.data(withJSONObject: header, options: [.sortedKeys])
        let pd = try! JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        return "\(base64URLEncode(hd)).\(base64URLEncode(pd)).\(signature)"
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
