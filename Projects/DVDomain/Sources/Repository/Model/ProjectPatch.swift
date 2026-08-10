// Copyright © 2026 Devault. All rights reserved

import Foundation

/// Project의 일부 필드 변경 요청을 표현합니다. (현재는 name만, 후에 확장성을 고려함)
public struct ProjectPatch: Equatable, Sendable {
    public var name: PatchField<String>
    public var updatedAt: PatchField<Date>

    public init(
        name: PatchField<String> = .unchanged,
        updatedAt: PatchField<Date> = .unchanged
    ) {
        self.name = name
        self.updatedAt = updatedAt
    }
}
