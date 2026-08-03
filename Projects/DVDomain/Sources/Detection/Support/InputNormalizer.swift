// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 감지 파이프라인 입력 전처리기.
///
/// - trim(whitespacesAndNewlines)
/// - 64KB(=65_536 bytes) 초과 시 문자 경계에서 조용히 잘라냄. UTF-8 multi-byte 문자가 부분적으로
///   포함되지 않도록 문자 단위로 누적한다.
enum InputNormalizer {
    static let maxByteCount = 64 * 1024

    static func normalize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.utf8.count > maxByteCount else { return trimmed }
        var result = ""
        var byteCount = 0
        for character in trimmed {
            let charBytes = character.utf8.count
            if byteCount + charBytes > maxByteCount { break }
            result.append(character)
            byteCount += charBytes
        }
        return result
    }
}
