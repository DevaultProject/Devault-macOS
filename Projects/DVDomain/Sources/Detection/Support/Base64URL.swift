// Copyright © 2026 Devault. All rights reserved

import Foundation

/// URL-safe base64 문자열 디코더. JWT header · payload 파싱 등에 사용.
///
/// - 표준 base64 alphabet의 `+`, `/`를 `-`, `_`로 치환한 변형.
/// - padding(`=`)이 생략되어 있어도 4의 배수가 되도록 보정.
enum Base64URL {
    static func decode(_ string: String) -> Data? {
        guard isValidAlphabet(string) else { return nil }
        var normalized = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let missingPadding = (4 - normalized.count % 4) % 4
        normalized += String(repeating: "=", count: missingPadding)
        return Data(base64Encoded: normalized)
    }

    /// base64URL alphabet(`A-Z` · `a-z` · `0-9` · `-` · `_`) 이외의 문자가 있으면 false.
    /// 표준 base64의 `+`, `/`, `=`을 명시적으로 거절해 malformed input을 조기 차단한다.
    private static func isValidAlphabet(_ string: String) -> Bool {
        string.utf8.allSatisfy { byte in
            (byte >= 0x30 && byte <= 0x39)  // 0-9
                || (byte >= 0x41 && byte <= 0x5A)  // A-Z
                || (byte >= 0x61 && byte <= 0x7A)  // a-z
                || byte == 0x2D  // -
                || byte == 0x5F  // _
        }
    }
}
