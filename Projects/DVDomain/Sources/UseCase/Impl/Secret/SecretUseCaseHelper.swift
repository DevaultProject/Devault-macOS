// Copyright © 2026 Devault. All rights reserved

import Foundation

enum SecretUseCaseHelper {
    /// Secret 초안의 이름을 정규화하고 필수값을 검증한 초안을 반환합니다.
    static func normalizedDraft(_ draft: SecretDraft) throws -> SecretDraft {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw SecretUseCaseError.invalidName }

        var normalized = draft
        normalized.name = name
        return normalized
    }

    /// patch에 updatedAt이 없으면 전달받은 시각으로 채웁니다.
    static func settingUpdatedAtIfNeeded(_ patch: SecretPatch, now: Date) -> SecretPatch {
        var next = patch
        if case .unchanged = next.updatedAt {
            next.updatedAt = .set(now)
        }
        return next
    }
}
