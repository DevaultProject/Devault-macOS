// Copyright © 2026 Devault. All rights reserved

import Foundation

enum SecretUseCaseHelper {
    /// Secret 초안의 기본 필수값을 검증합니다.
    static func validateDraft(_ draft: SecretDraft) throws {
        guard !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SecretUseCaseError.invalidName
        }

        guard !draft.secretType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SecretUseCaseError.invalidSecretType
        }
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
