// Copyright © 2026 Devault. All rights reserved

import Foundation

/// prefix로 잡히지 않는 서비스(고정 자릿수 · 특정 포맷)를 위한 wholeMatch regex 카탈로그.
enum BuiltInRegexRules {
    static let all: [RegexRule] = [
        .init(
            pattern: #"AC[a-f0-9]{32}"#,
            service: "Twilio",
            displayLabel: "Twilio Account SID",
            confidence: .high
        ),
        .init(
            pattern: #"key-[a-f0-9]{32}"#,
            service: "Mailgun",
            displayLabel: "Mailgun API Key",
            confidence: .high
        ),
        .init(
            pattern: #"[a-z0-9]{32}-us[0-9]+"#,
            service: "Mailchimp",
            displayLabel: "Mailchimp API Key",
            confidence: .high
        ),
        .init(
            pattern: #"[0-9]+:[A-Za-z0-9_-]{35}"#,
            service: "Telegram",
            displayLabel: "Telegram Bot Token",
            confidence: .high
        ),
        .init(
            pattern: #"[MN][A-Za-z0-9]{23,25}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27}"#,
            service: "Discord",
            displayLabel: "Discord Bot Token",
            confidence: .high
        ),
        .init(
            pattern: #"https://[a-f0-9]+@[a-z0-9.-]+\.ingest\.sentry\.io/[0-9]+"#,
            service: "Sentry",
            displayLabel: "Sentry DSN",
            confidence: .high
        ),
    ]
}
