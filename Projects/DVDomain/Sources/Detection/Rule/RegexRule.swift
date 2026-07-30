// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct RegexRule: Equatable, Sendable {
    /// wholeMatch용 정규식 문자열
    public var pattern: String
    /// 후보 chip에 표시할 짧은 서비스명
    public var service: String
    /// 툴팁 · 긴 라벨
    public var displayLabel: String
    /// 매칭 신뢰도
    public var confidence: DetectionConfidence

    public init(
        pattern: String,
        service: String,
        displayLabel: String,
        confidence: DetectionConfidence
    ) {
        self.pattern = pattern
        self.service = service
        self.displayLabel = displayLabel
        self.confidence = confidence
    }
}
