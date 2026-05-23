// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 평문 JSON으로 저장 가능한 Secret metadata content가 따라야 하는 Domain 계약입니다.
public protocol SecretMetadataContent: Codable, Sendable {
    static var schemaVersion: Int { get }
}
