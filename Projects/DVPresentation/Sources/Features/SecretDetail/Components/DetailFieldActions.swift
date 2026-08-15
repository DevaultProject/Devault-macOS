// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 조회 필드의 마스킹 상태와 눈·복사 동작을 한 묶음으로 내려보낸다.
///
/// 파라미터로 넘기지 않고 Environment를 쓰는 이유는 **전달 경로 때문**이다. 필드는 9개 섹션 뷰
/// 안쪽에 흩어져 있어서, 세 값을 파라미터로 받으면 중간 섹션들이 자기가 쓰지도 않는 값을
/// 계속 실어 나르게 된다. 섹션은 필드마다 `field:` 식별자만 붙이면 된다.
///
/// 마스킹되는 값은 담지 않는다 — 복사할 원문은 식별자만 받아 Feature가 payload에서 꺼낸다.
/// 마스킹된 값이 뷰 트리를 통과하지 않게 하려는 것이다. 이미 화면에 그려져 있는 평문은
/// 가릴 것이 없으므로 값을 그대로 넘긴다.
struct DetailFieldActions {

    /// 현재 마스킹이 해제된 필드.
    var revealedFields: Set<SecretFieldID> = []

    /// 눈 버튼. 인증과 복호화는 Feature가 판단한다.
    var onToggleReveal: (SecretFieldID) -> Void = { _ in }

    /// 민감 필드의 복사 버튼. 클립보드 쓰기와 자동 정리는 Feature가 UseCase로 수행한다.
    var onCopy: (SecretFieldID) -> Void = { _ in }

    /// 평문 필드의 복사 버튼. metadata·secret에서 온 값이라 payload에서 꺼낼 식별자가 없고,
    /// 복호화할 것도 없어 인증을 태우지 않는다.
    var onCopyPlainValue: (String) -> Void = { _ in }

    func isRevealed(_ field: SecretFieldID?) -> Bool {
        guard let field else { return false }
        return revealedFields.contains(field)
    }
}

extension EnvironmentValues {

    /// 조회 필드 동작. 프리뷰처럼 주입이 없는 자리에서는 아무 일도 하지 않는 기본값이 쓰인다.
    @Entry var detailFieldActions = DetailFieldActions()
}
