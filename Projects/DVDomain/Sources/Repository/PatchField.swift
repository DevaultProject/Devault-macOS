// Copyright © 2026 Devault. All rights reserved

/// 일부 필드 변경 요청에서 변경 없음과 새 값을 구분합니다.
public enum PatchField<Value: Equatable & Sendable>: Equatable, Sendable {
    case unchanged
    case set(Value)
}
