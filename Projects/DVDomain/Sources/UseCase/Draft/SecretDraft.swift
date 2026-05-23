// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 아직 저장되지 않은 Secret 초안 정보를 표현합니다.
public struct SecretDraft: Equatable, Sendable {
    public var name: String
    public var secretType: String
    public var subType: String?
    public var service: String?
    public var environment: String?
    public var expiresAt: Date?
    public var memo: String?
    public var liked: Bool

    public init(
        name: String,
        secretType: String,
        subType: String? = nil,
        service: String? = nil,
        environment: String? = nil,
        expiresAt: Date? = nil,
        memo: String? = nil,
        liked: Bool = false
    ) {
        self.name = name
        self.secretType = secretType
        self.subType = subType
        self.service = service
        self.environment = environment
        self.expiresAt = expiresAt
        self.memo = memo
        self.liked = liked
    }
}
