// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 앱 번들에 정적으로 임베드된 시크릿 패턴 저장소.
public struct BundledSecretPatternRepository: SecretPatternRepository {
    public init() {}

    public func prefixRules() -> [PrefixRule] { BuiltInPrefixRules.all }
    public func regexRules() -> [RegexRule] { BuiltInRegexRules.all }
    public func databaseSchemes() -> [DatabaseSchemeRule] { BuiltInDatabaseSchemes.all }
    public func pemHeaders() -> [PEMHeaderRule] { BuiltInPEMHeaders.all }
}
