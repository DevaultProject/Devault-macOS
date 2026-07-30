// Copyright © 2026 Devault. All rights reserved

import Foundation

struct PrefixRegexDetector: SecretDetector {
    let prefixRules: [PrefixRule]
    let regexRules: [RegexRule]

    func detect(_ value: SensitiveString, context: DetectorContext) -> DetectionResult? {
        value.withUnsafeAccess { raw in
            let prefixMatches = prefixRules.filter { rule in
                guard raw.hasPrefix(rule.prefix) else { return false }
                if let min = rule.minLength, raw.count < min { return false }
                if let ctx = rule.requiresContext,
                   !raw.lowercased().contains(ctx.lowercased()) { return false }
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

            for rule in regexRules {
                guard let re = try? Regex(rule.pattern) else { continue }
                guard let match = try? re.wholeMatch(in: raw), match != nil else { continue }
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
}
