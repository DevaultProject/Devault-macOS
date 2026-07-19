// Copyright © 2026 Devault. All rights reserved

import Foundation

/// `SecretMetaFields` → 도메인 매핑(`toCreateSecretPayload`) 시 발생하는 폼 검증 실패.
enum FormError: Error, Equatable {
    /// 필수 필드가 비어 있음. 어느 필드인지 `FieldID`로 지목.
    case missingRequired(SecretMetaFields.FieldID)
    
    /// secretType / subType 조합이 지원되지 않음. 정상 흐름에선 발생하지 않는 방어적 케이스.
    case invalidTypeCombination
}
