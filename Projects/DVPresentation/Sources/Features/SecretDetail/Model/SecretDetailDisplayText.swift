// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVDomain

// MARK: - 조회 화면 표시 문자열

/// 도메인 값 → 조회 화면에 뿌릴 문자열 변환.
///
/// 생성 화면은 각 값을 전용 컨트롤(`DatePicker` / `Picker` / `DVMultiSelectDropdown`)로 다루지만
/// 조회 화면은 전부 `DetailReadOnlyFieldView`의 `String`으로 표시한다. 그 변환을 한곳에 모은다.
///
/// 값이 없으면 **빈 문자열**을 반환한다 — `DVTextContainer`의 Empty 상태(박스만 표시)로 렌더되며,
/// 이는 디자인 시스템이 명시적으로 지원하는 상태다. `"—"` 같은 대체 기호를 새로 만들지 않는다.
extension Secret {

    /// `SecretDraft.environment`에 `SecretEnvironment.rawValue`로 저장된 값을 표시명으로 되돌린다.
    /// 매핑되지 않는 값이면 원문을 그대로 보여준다 — 조회 화면이 값을 숨기면 안 된다.
    var environmentDisplayText: String {
        guard let environment else { return "" }
        guard let known = SecretEnvironment(rawValue: environment) else { return environment }
        return String(localized: known.displayName)
    }

    /// 만료일. 생성 화면 `ExpireDateFieldView`가 native stepper의 locale 포맷을 쓰므로
    /// 조회 화면도 locale 기준 숫자 날짜로 맞춘다.
    var expireDateDisplayText: String {
        guard let expiresAt else { return "" }
        return expiresAt.formatted(date: .numeric, time: .omitted)
    }

    var serviceDisplayText: String { service ?? "" }

    var memoDisplayText: String { memo ?? "" }
}
