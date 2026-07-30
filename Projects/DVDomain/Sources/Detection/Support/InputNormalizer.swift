// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 감지 파이프라인 입력 전처리기.
///
/// - trim(whitespacesAndNewlines)
/// - 64KB(=65_536 bytes) 초과 시 조용히 잘라냄
enum InputNormalizer {
    static let maxByteCount = 64 * 1024

    static func normalize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.utf8.count > maxByteCount else { return trimmed }
        return String(trimmed.utf8.prefix(maxByteCount).map { Character(UnicodeScalar($0)) })
    }
}
