// Copyright © 2026 Devault. All rights reserved

import DVDesign
import Foundation

/// CreateSecret SectionView들이 공유하는 인라인 hint(경고/감지) 파생 규칙.
/// 각 SectionView는 `validationErrors` + `detectedServices`를 stored로만 노출하면
/// default `hintFor(_:)` 구현으로 `DVFieldTrailingHint` 파생.
///
/// 우선순위: warning(validation) > detected(감지) — validation 실패 시 감지 결과는 숨김.
protocol CreateSecretSectionHintProviding {
    var validationErrors: [SecretMetaFields.FieldID: String] { get }
    var detectedServices: [SecretMetaFields.FieldID: String] { get }
}

extension CreateSecretSectionHintProviding {
    func hintFor(_ id: SecretMetaFields.FieldID) -> DVFieldTrailingHint? {
        if let warning = validationErrors[id] {
            return .warning(warning)
        }
        if let value = detectedServices[id] {
            return .detected(.module("Auto-detected: \(value)"))
        }
        return nil
    }
}
