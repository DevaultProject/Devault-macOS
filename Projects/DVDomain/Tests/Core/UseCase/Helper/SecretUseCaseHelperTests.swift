// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("SecretUseCaseHelper")
struct SecretUseCaseHelperTests {
    // MARK: - normalizedDraft

    @Test("normalizedDraft는 이름의 앞뒤 공백을 제거하고 나머지 필드는 그대로 유지한다")
    func normalizedDraftTrimsName() throws {
        let draft = SecretDraft(
            name: "  Hello  ",
            secretType: .apiKeyToken,
            subType: .apiKey,
            service: "GitHub",
            environment: "prod",
            memo: "note",
            liked: true
        )

        let normalized = try SecretUseCaseHelper.normalizedDraft(draft)

        #expect(normalized.name == "Hello")
        #expect(normalized.secretType == .apiKeyToken)
        #expect(normalized.subType == .apiKey)
        #expect(normalized.service == "GitHub")
        #expect(normalized.environment == "prod")
        #expect(normalized.memo == "note")
        #expect(normalized.liked == true)
    }

    @Test("빈 이름은 invalidName 에러를 던진다")
    func normalizedDraftRejectsEmptyName() {
        let draft = SecretDraft(name: "", secretType: .apiKeyToken)

        #expect(throws: SecretUseCaseError.invalidName) {
            _ = try SecretUseCaseHelper.normalizedDraft(draft)
        }
    }

    @Test("공백만 있는 이름은 invalidName 에러를 던진다")
    func normalizedDraftRejectsWhitespaceName() {
        let draft = SecretDraft(name: "  \n\t ", secretType: .apiKeyToken)

        #expect(throws: SecretUseCaseError.invalidName) {
            _ = try SecretUseCaseHelper.normalizedDraft(draft)
        }
    }

    // MARK: - settingUpdatedAtIfNeeded

    @Test("updatedAt이 unchanged면 주입 시각으로 채운다")
    func settingUpdatedAtFillsWhenUnchanged() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let patch = SecretPatch(liked: .set(true))

        let filled = SecretUseCaseHelper.settingUpdatedAtIfNeeded(patch, now: now)

        #expect(filled.updatedAt == .set(now))
        #expect(filled.liked == .set(true))
    }

    @Test("updatedAt이 이미 set이면 원래 값을 유지한다")
    func settingUpdatedAtPreservesExplicit() {
        let explicit = Date(timeIntervalSince1970: 1_500_000_000)
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let patch = SecretPatch(liked: .set(true), updatedAt: .set(explicit))

        let filled = SecretUseCaseHelper.settingUpdatedAtIfNeeded(patch, now: now)

        #expect(filled.updatedAt == .set(explicit))
    }
}
