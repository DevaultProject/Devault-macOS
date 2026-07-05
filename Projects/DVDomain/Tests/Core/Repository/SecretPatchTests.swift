// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("SecretPatch")
struct SecretPatchTests {
    @Test("기본 생성자는 모든 필드를 unchanged로 만든다")
    func defaultInitLeavesAllUnchanged() {
        let patch = SecretPatch()

        #expect(patch.name == .unchanged)
        #expect(patch.secretType == .unchanged)
        #expect(patch.subType == .unchanged)
        #expect(patch.service == .unchanged)
        #expect(patch.environment == .unchanged)
        #expect(patch.expiresAt == .unchanged)
        #expect(patch.memo == .unchanged)
        #expect(patch.liked == .unchanged)
        #expect(patch.deletedAt == .unchanged)
        #expect(patch.payload == .unchanged)
        #expect(patch.metadata == .unchanged)
        #expect(patch.updatedAt == .unchanged)
    }

    @Test("특정 필드만 set으로 초기화하면 나머지는 unchanged로 유지된다")
    func partialInitLeavesOthersUnchanged() {
        let patch = SecretPatch(liked: .set(true))

        #expect(patch.liked == .set(true))
        #expect(patch.name == .unchanged)
        #expect(patch.updatedAt == .unchanged)
    }

    @Test("PatchField.set은 감싼 값이 다르면 다르다")
    func patchFieldEqualityDistinguishesSetValues() {
        #expect(PatchField.set("A") != PatchField.set("B"))
        #expect(PatchField.set("A") == PatchField.set("A"))
    }

    @Test("PatchField.unchanged와 .set은 서로 다르다")
    func patchFieldEqualityDistinguishesUnchangedAndSet() {
        #expect(PatchField<String>.unchanged != .set(""))
    }
}
