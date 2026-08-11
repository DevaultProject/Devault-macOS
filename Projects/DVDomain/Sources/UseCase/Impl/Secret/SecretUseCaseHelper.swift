// Copyright © 2026 Devault. All rights reserved

import Foundation

enum SecretUseCaseHelper {
    /// Secret 초안의 이름을 정규화하고, expiresAt이 있으면 그 날의 23:59:59로 고정한 초안을 반환합니다.
    static func normalizedDraft(_ draft: SecretDraft) throws -> SecretDraft {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw SecretUseCaseError.invalidName }

        var normalized = draft
        normalized.name = name
        normalized.expiresAt = normalized.expiresAt.map(Self.endOfDay)
        return normalized
    }

    private static func endOfDay(_ date: Date) -> Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
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
