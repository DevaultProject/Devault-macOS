// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 시크릿 감지에 사용되는 정적 패턴 규칙 저장소.
///
/// - 규칙은 앱 도메인 상수이므로 기본 구현은 `BundledSecretPatternRepository` (in-memory bundled).
/// - 원격 룰 로딩은 후속 이슈에서 별도 구현체로 스와핑.
public protocol SecretPatternRepository: Sendable {
    /// prefix 길이 내림차순으로 정렬된 rule 목록.
    func prefixRules() -> [PrefixRule]
    /// wholeMatch용 regex rule 목록.
    func regexRules() -> [RegexRule]
    /// URL 스킴 rule 목록.
    func databaseSchemes() -> [DatabaseSchemeRule]
    /// PEM 헤더 rule 목록 (헤더 문자열 길이 내림차순).
    func pemHeaders() -> [PEMHeaderRule]
}
