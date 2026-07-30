// Copyright © 2026 Devault. All rights reserved

import Foundation

/// `eyJ` prefix + `.` 3-part base64URL 형태의 JWT 감지. header/payload를 파싱해 알고리즘 · issuer · exp 등을 추출.
///
/// 후보 chip은 부여하지 않는다. JWT는 포맷 정보일 뿐 서비스 식별자가 아니므로 metadata만 채운다.
/// 서비스가 있는 JWT 기반 토큰(예: Mapbox `pk.eyJ`)은 앞선 `PrefixRegexDetector`에서 이미 매칭된다.
struct JWTDetector: SecretDetector {
    func detect(_ value: SensitiveString, context: DetectorContext) -> DetectionResult? {
        value.withUnsafeAccess { raw in
            guard raw.hasPrefix("eyJ") else { return nil }
            let parts = raw.split(separator: ".", omittingEmptySubsequences: false)
            guard parts.count == 3,
                  !parts[0].isEmpty,
                  !parts[1].isEmpty,
                  let headerData = Base64URL.decode(String(parts[0])),
                  let payloadData = Base64URL.decode(String(parts[1])),
                  let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any],
                  let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
            else { return nil }

            let algorithm = header["alg"] as? String
            let issuer = payload["iss"] as? String
            let subject = payload["sub"] as? String
            let expiresAt: Date? = (payload["exp"] as? NSNumber).map {
                Date(timeIntervalSince1970: $0.doubleValue)
            }

            return DetectionResult(
                candidates: [],
                metadata: .jwt(.init(
                    algorithm: algorithm,
                    issuer: issuer,
                    subject: subject,
                    expiresAt: expiresAt
                ))
            )
        }
    }
}
