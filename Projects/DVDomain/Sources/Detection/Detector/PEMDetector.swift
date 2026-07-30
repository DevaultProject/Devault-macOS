// Copyright © 2026 Devault. All rights reserved

import Foundation

struct PEMDetector: SecretDetector {
    let rules: [PEMHeaderRule]

    func detect(_ value: SensitiveString, context: DetectorContext) -> DetectionResult? {
        value.withUnsafeAccess { raw in
            let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let rule = rules.first(where: { normalized.contains($0.header) }) else {
                return nil
            }
            let metadata: DetectedMetadata
            if rule.isCertificate {
                metadata = .certificate(.init())
            } else {
                let algorithm: String? = {
                    guard rule.keyType == "OpenSSH",
                          normalized.lowercased().contains("ed25519") else { return nil }
                    return "ed25519"
                }()
                metadata = .pemKey(.init(keyType: rule.keyType, algorithm: algorithm))
            }
            return DetectionResult(candidates: [], metadata: metadata)
        }
    }
}
