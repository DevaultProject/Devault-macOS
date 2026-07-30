// Copyright © 2026 Devault. All rights reserved

import Foundation

/// `eyJ` prefix + `.` 3-part base64URL 형태의 JWT 감지. header/payload를 파싱해 알고리즘 · issuer · exp 등을 추출.
///
/// 현재는 파싱 로직 미구현. 파이프라인에서 항상 fall-through.
struct JWTDetector: SecretDetector {
    func detect(_ value: SensitiveString, context: DetectorContext) -> DetectionResult? {
        nil
    }
}
