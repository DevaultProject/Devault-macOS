// Copyright © 2026 Devault. All rights reserved

import Foundation

struct PrefixRegexDetector: SecretDetector {
    let prefixRules: [PrefixRule]
    /// Init 시점에 한 번 컴파일해서 재사용. 매 keystroke마다 재컴파일하지 않도록.
    private let compiledRegex: [(rule: RegexRule, regex: Regex<AnyRegexOutput>)]

    init(prefixRules: [PrefixRule], regexRules: [RegexRule]) {
        self.prefixRules = prefixRules
        self.compiledRegex = regexRules.compactMap { rule in
            guard let regex = try? Regex(rule.pattern) else { return nil }
            return (rule, regex)
        }
    }

    func detect(_ value: SensitiveString, context: DetectorContext) -> DetectionResult? {
        value.withUnsafeAccess { raw in
            let prefixMatches = prefixRules.filter { rule in
                guard raw.hasPrefix(rule.prefix) else { return false }
                if let min = rule.minLength, raw.count < min { return false }
                if let ctx = rule.requiresContext, !containsContext(raw, ctx: ctx) {
                    return false
                }
                return true
            }
            if !prefixMatches.isEmpty {
                let candidates = prefixMatches
                    .map { r in
                        ServiceCandidate(
                            service: r.service,
                            displayLabel: r.displayLabel,
                            confidence: r.confidence
                        )
                    }
                    .sorted { $0.confidence > $1.confidence }
                return DetectionResult(candidates: candidates)
            }

            for (rule, regex) in compiledRegex {
                guard let match = try? regex.wholeMatch(in: raw), match != nil else { continue }
                return DetectionResult(candidates: [
                    ServiceCandidate(
                        service: rule.service,
                        displayLabel: rule.displayLabel,
                        confidence: rule.confidence
                    )
                ])
            }
            return nil
        }
    }

    /// context 매칭. context에 letter가 없으면 (심볼·숫자만) raw 전체 lowercasing을 생략해 대용량 입력에서의 복사 비용을 아낀다.
    private func containsContext(_ raw: String, ctx: String) -> Bool {
        let needsFolding = ctx.contains(where: { $0.isLetter })
        return needsFolding
            ? raw.lowercased().contains(ctx.lowercased())
            : raw.contains(ctx)
    }
}
