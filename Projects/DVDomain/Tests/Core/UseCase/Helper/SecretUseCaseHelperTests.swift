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

    @Test("normalizedDraft는 expiresAt의 날짜(연/월/일)는 유지한 채 시:분:초를 23:59:59로 고정한다")
    func normalizedDraftAnchorsExpiresAtToEndOfDay() throws {
        let pickedDate = DateComponents(
            calendar: .current, year: 2026, month: 8, day: 14, hour: 9, minute: 0, second: 0
        ).date!
        let draft = SecretDraft(name: "Hello", secretType: .apiKeyToken, expiresAt: pickedDate)

        let normalized = try SecretUseCaseHelper.normalizedDraft(draft)

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: try #require(normalized.expiresAt)
        )
        #expect(components.year == 2026)
        #expect(components.month == 8)
        #expect(components.day == 14)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
        #expect(components.second == 59)
    }

    @Test("normalizedDraft는 expiresAt이 nil이면 nil을 유지한다")
    func normalizedDraftKeepsNilExpiresAt() throws {
        let draft = SecretDraft(name: "Hello", secretType: .apiKeyToken, expiresAt: nil)

        let normalized = try SecretUseCaseHelper.normalizedDraft(draft)

        #expect(normalized.expiresAt == nil)
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

    // MARK: - normalizedPatch

    @Test("normalizedPatch는 set된 이름의 앞뒤 공백을 제거하고 나머지 필드는 그대로 둔다")
    func normalizedPatchTrimsName() throws {
        let patch = SecretPatch(
            name: .set("  Hello  "),
            service: .set("GitHub"),
            memo: .set("note"),
            liked: .set(true)
        )

        let normalized = try SecretUseCaseHelper.normalizedPatch(patch)

        #expect(normalized.name == .set("Hello"))
        #expect(normalized.service == .set("GitHub"))
        #expect(normalized.memo == .set("note"))
        #expect(normalized.liked == .set(true))
    }

    @Test("normalizedPatch는 이름이 unchanged면 건드리지 않는다")
    func normalizedPatchKeepsUnchangedName() throws {
        let normalized = try SecretUseCaseHelper.normalizedPatch(SecretPatch(liked: .set(true)))

        #expect(normalized.name == .unchanged)
    }

    @Test("normalizedPatch는 expiresAt의 날짜는 유지한 채 시:분:초를 23:59:59로 고정한다")
    func normalizedPatchAnchorsExpiresAtToEndOfDay() throws {
        let pickedDate = DateComponents(
            calendar: .current, year: 2026, month: 8, day: 14, hour: 9, minute: 0, second: 0
        ).date!

        let normalized = try SecretUseCaseHelper.normalizedPatch(
            SecretPatch(expiresAt: .set(pickedDate))
        )

        guard case .set(let anchored?) = normalized.expiresAt else {
            Issue.record("expiresAt이 set이어야 한다")
            return
        }
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: anchored
        )
        #expect(components.year == 2026)
        #expect(components.month == 8)
        #expect(components.day == 14)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
        #expect(components.second == 59)
    }

    @Test("normalizedPatch는 만료일 삭제 요청(.set(nil))을 그대로 전달한다")
    func normalizedPatchKeepsExpiresAtClearRequest() throws {
        let normalized = try SecretUseCaseHelper.normalizedPatch(
            SecretPatch(expiresAt: .set(nil))
        )

        #expect(normalized.expiresAt == .set(nil))
    }

    @Test("normalizedPatch는 expiresAt이 unchanged면 건드리지 않는다")
    func normalizedPatchKeepsUnchangedExpiresAt() throws {
        let normalized = try SecretUseCaseHelper.normalizedPatch(SecretPatch(liked: .set(true)))

        #expect(normalized.expiresAt == .unchanged)
    }

    @Test("normalizedPatch는 빈 이름을 invalidName으로 거부한다")
    func normalizedPatchRejectsEmptyName() {
        #expect(throws: SecretUseCaseError.invalidName) {
            _ = try SecretUseCaseHelper.normalizedPatch(SecretPatch(name: .set("")))
        }
    }

    @Test("normalizedPatch는 공백만 있는 이름을 invalidName으로 거부한다")
    func normalizedPatchRejectsWhitespaceName() {
        #expect(throws: SecretUseCaseError.invalidName) {
            _ = try SecretUseCaseHelper.normalizedPatch(SecretPatch(name: .set("  \n\t ")))
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
