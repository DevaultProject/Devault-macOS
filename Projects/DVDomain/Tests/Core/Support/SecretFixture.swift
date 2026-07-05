// Copyright © 2026 Devault. All rights reserved

import Foundation

@testable import DVDomain

/// Secret 관련 테스트 fixture 팩토리.
public enum SecretFixture {
    public static let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    public static let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    public static let defaultPayload = SecretPayload(
        encryptedData: Data("encrypted-body".utf8),
        keyTag: "fake-key-tag",
        schemaVersion: 1
    )

    public static func make(
        id: UUID = fixedID,
        name: String = "Test Secret",
        secretType: SecretType = .apiKeyToken,
        subType: SecretSubType? = .apiKey,
        service: String? = nil,
        environment: String? = nil,
        expiresAt: Date? = nil,
        memo: String? = nil,
        liked: Bool = false,
        deletedAt: Date? = nil,
        createdAt: Date = fixedDate,
        updatedAt: Date = fixedDate,
        payload: SecretPayload = defaultPayload,
        metadata: SecretMetadata? = nil
    ) -> Secret {
        Secret(
            id: id,
            name: name,
            secretType: secretType,
            subType: subType,
            service: service,
            environment: environment,
            expiresAt: expiresAt,
            memo: memo,
            liked: liked,
            deletedAt: deletedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            payload: payload,
            metadata: metadata
        )
    }

    public static func draft(
        name: String = "Test Secret",
        secretType: SecretType = .apiKeyToken,
        subType: SecretSubType? = .apiKey,
        service: String? = nil,
        environment: String? = nil,
        expiresAt: Date? = nil,
        memo: String? = nil,
        liked: Bool = false
    ) -> SecretDraft {
        SecretDraft(
            name: name,
            secretType: secretType,
            subType: subType,
            service: service,
            environment: environment,
            expiresAt: expiresAt,
            memo: memo,
            liked: liked
        )
    }
}
