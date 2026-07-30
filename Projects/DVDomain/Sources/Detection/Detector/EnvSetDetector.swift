// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 여러 줄 KEY=VALUE 형태(`.env` 파일 등) 감지. 각 VALUE는 파이프라인을 재귀 호출해 세부 감지.
///
/// 매칭 조건: 2줄 이상 · KEY는 `UPPER_SNAKE_CASE` (첫 문자 대문자) · `#` 주석 라인 무시 · 빈 라인 무시.
/// 위 조건 중 하나라도 어긋나면(파싱된 유효 라인이 2건 미만) `nil` 반환 → 다음 detector로 fall-through.
struct EnvSetDetector: SecretDetector {
    func detect(_ value: SensitiveString, context: DetectorContext) -> DetectionResult? {
        value.withUnsafeAccess { raw in
            let entries = parseEntries(raw)
            guard entries.count >= 2 else { return nil }

            let subDetections = entries.map { entry in
                SubDetection(
                    key: entry.key,
                    result: context.detect(SensitiveString(entry.value))
                )
            }
            return DetectionResult(
                candidates: [],
                metadata: .envSet(keys: entries.map(\.key)),
                subDetections: subDetections
            )
        }
    }

    private func parseEntries(_ raw: String) -> [(key: String, value: String)] {
        raw.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return nil }
            guard let equalsIndex = trimmed.firstIndex(of: "=") else { return nil }
            let key = String(trimmed[..<equalsIndex])
            guard isValidEnvKey(key) else { return nil }
            let rawValue = String(trimmed[trimmed.index(after: equalsIndex)...])
            return (key, stripQuotes(rawValue))
        }
    }

    private func isValidEnvKey(_ key: String) -> Bool {
        guard let first = key.unicodeScalars.first,
              CharacterSet.uppercaseLetters.contains(first) else { return false }
        let allowed = CharacterSet.uppercaseLetters
            .union(CharacterSet.decimalDigits)
            .union(CharacterSet(charactersIn: "_"))
        return key.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private func stripQuotes(_ value: String) -> String {
        guard value.count >= 2 else { return value }
        let first = value.first!
        let last = value.last!
        if (first == "\"" && last == "\"") || (first == "'" && last == "'") {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}
