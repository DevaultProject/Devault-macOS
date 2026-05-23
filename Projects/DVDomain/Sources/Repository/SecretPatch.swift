// Copyright © 2026 Devault. All rights reserved

import Foundation

/// Secret의 일부 필드 변경 요청을 표현합니다.
public struct SecretPatch: Equatable, Sendable {
    public var name: PatchField<String>
    public var secretType: PatchField<String>
    public var subType: PatchField<String?>
    public var service: PatchField<String?>
    public var environment: PatchField<String?>
    public var expiresAt: PatchField<Date?>
    public var memo: PatchField<String?>
    public var liked: PatchField<Bool>
    public var deletedAt: PatchField<Date?>
    public var payload: PatchField<SecretPayload>
    public var metadata: PatchField<SecretMetadata?>
    public var updatedAt: PatchField<Date>

    public init(
        name: PatchField<String> = .unchanged,
        secretType: PatchField<String> = .unchanged,
        subType: PatchField<String?> = .unchanged,
        service: PatchField<String?> = .unchanged,
        environment: PatchField<String?> = .unchanged,
        expiresAt: PatchField<Date?> = .unchanged,
        memo: PatchField<String?> = .unchanged,
        liked: PatchField<Bool> = .unchanged,
        deletedAt: PatchField<Date?> = .unchanged,
        payload: PatchField<SecretPayload> = .unchanged,
        metadata: PatchField<SecretMetadata?> = .unchanged,
        updatedAt: PatchField<Date> = .unchanged
    ) {
        self.name = name
        self.secretType = secretType
        self.subType = subType
        self.service = service
        self.environment = environment
        self.expiresAt = expiresAt
        self.memo = memo
        self.liked = liked
        self.deletedAt = deletedAt
        self.payload = payload
        self.metadata = metadata
        self.updatedAt = updatedAt
    }
}

public enum PatchField<Value: Equatable & Sendable>: Equatable, Sendable {
    case unchanged
    case set(Value)
}
