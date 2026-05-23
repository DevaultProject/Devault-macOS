// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 암호화 대상 Secret payload content가 따라야 하는 Domain 계약입니다.
public protocol SecretPayloadData: Codable, Sendable {
    static var schemaVersion: Int { get }
}
