// Copyright © 2026 Devault. All rights reserved

import Foundation

/// URL-safe base64 문자열 디코더. JWT header · payload 파싱 등에 사용.
///
/// - 표준 base64 alphabet의 `+`, `/`를 `-`, `_`로 치환한 변형.
/// - padding(`=`)이 생략되어 있어도 4의 배수가 되도록 보정.
enum Base64URL {
    static func decode(_ string: String) -> Data? {
        var normalized = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let missingPadding = (4 - normalized.count % 4) % 4
        normalized += String(repeating: "=", count: missingPadding)
        return Data(base64Encoded: normalized)
    }
}
