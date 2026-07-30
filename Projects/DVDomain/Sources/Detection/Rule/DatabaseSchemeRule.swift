// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct DatabaseSchemeRule: Equatable, Sendable {
    /// URL scheme (예: "postgresql", "mongodb+srv")
    public var scheme: String
    /// scheme별 표준 기본 포트. URL에 포트가 명시 안 됐을 때 채워 넣음.
    public var defaultPort: Int?

    public init(scheme: String, defaultPort: Int? = nil) {
        self.scheme = scheme
        self.defaultPort = defaultPort
    }
}
