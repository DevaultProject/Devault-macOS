// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct ServiceCandidate: Equatable, Sendable {
    /// chip 텍스트 (예: "OpenAI", "GitHub PAT", "Neon")
    public var service: String
    /// 툴팁 · 긴 라벨 (예: "OpenAI API Key")
    public var displayLabel: String
    /// 매칭 신뢰도
    public var confidence: DetectionConfidence

    public init(service: String, displayLabel: String, confidence: DetectionConfidence) {
        self.service = service
        self.displayLabel = displayLabel
        self.confidence = confidence
    }
}
