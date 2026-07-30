// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 앱 번들에 정적으로 임베드된 prefix rule 카탈로그. 카테고리별로 서브네임스페이스에 나누어 관리한다.
enum BuiltInPrefixRules {
    /// AI · LLM 서비스 API key prefix.
    static let ai: [PrefixRule] = [
        .init(
            prefix: "sk-ant-",
            service: "Anthropic",
            displayLabel: "Anthropic API Key",
            confidence: .high
        ),
        .init(
            prefix: "sk-or-",
            service: "OpenRouter",
            displayLabel: "OpenRouter API Key",
            confidence: .high
        ),
        .init(
            prefix: "sk-",
            minLength: 48,
            requiresContext: "stability",
            service: "Stability AI",
            displayLabel: "Stability AI API Key",
            confidence: .high
        ),
        .init(
            prefix: "sk-",
            minLength: 48,
            service: "OpenAI",
            displayLabel: "OpenAI API Key",
            confidence: .medium
        ),
        .init(
            prefix: "hf_",
            service: "Hugging Face",
            displayLabel: "Hugging Face Token",
            confidence: .high
        ),
    ]

    /// prefix 길이 내림차순으로 정렬한 통합 목록. 짧은 prefix(예: `sk-`)가 긴 prefix(예: `sk-ant-`)보다
    /// 먼저 매칭돼 오탐하는 것을 막기 위한 순서 보장.
    static var all: [PrefixRule] {
        ai.sorted { $0.prefix.count > $1.prefix.count }
    }
}
