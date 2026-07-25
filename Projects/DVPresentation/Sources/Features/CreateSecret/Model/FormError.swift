// Copyright © 2026 Devault. All rights reserved

import Foundation

/// `SecretMetaFields` → 도메인 매핑(`toCreateSecretPayload`) 시 발생하는 폼 검증 실패.
enum FormError: Error, Equatable {
    /// 필수 필드가 비어 있음. 누락된 필드를 한 번에 모두 지목 (인라인 warning 다중 노출).
    case missingRequired([SecretMetaFields.FieldID])

    /// secretType / subType 조합이 지원되지 않음. 정상 흐름에선 발생하지 않는 방어적 케이스.
    case invalidTypeCombination
}
