// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct PrefixRule: Equatable, Sendable {
    /// 매칭할 prefix 문자열 (예: "sk-ant-", "ghp_")
    public var prefix: String
    /// 매칭에 필요한 전체 문자열 최소 길이. nil이면 길이 무관.
    public var minLength: Int?
    /// 소문자 부분 문자열 컨텍스트 요구 (예: "stability"). nil이면 컨텍스트 무관.
    public var requiresContext: String?
    /// 후보 chip에 표시할 짧은 서비스명
    public var service: String
    /// 툴팁 · 긴 라벨
    public var displayLabel: String
    /// 매칭 신뢰도
    public var confidence: DetectionConfidence

    public init(
        prefix: String,
        minLength: Int? = nil,
        requiresContext: String? = nil,
        service: String,
        displayLabel: String,
        confidence: DetectionConfidence
    ) {
        self.prefix = prefix
        self.minLength = minLength
        self.requiresContext = requiresContext
        self.service = service
        self.displayLabel = displayLabel
        self.confidence = confidence
    }
}
