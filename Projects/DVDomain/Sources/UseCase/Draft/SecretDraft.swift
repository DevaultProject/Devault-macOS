// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 아직 저장되지 않은 Secret 초안 정보를 표현합니다. 암호화 결과 등의 생성 책임을 UseCase 안으로 모으는 역할.
public struct SecretDraft: Equatable, Sendable {
    public var name: String
    public var secretType: SecretType
    public var subType: SecretSubType?
    public var service: String?
    public var environment: String?
    public var expiresAt: Date?
    public var memo: String?
    public var liked: Bool

    public init(
        name: String,
        secretType: SecretType,
        subType: SecretSubType? = nil,
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
