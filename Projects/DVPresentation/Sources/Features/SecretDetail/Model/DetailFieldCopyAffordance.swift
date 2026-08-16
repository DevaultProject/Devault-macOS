// Copyright © 2026 Devault. All rights reserved

/// 조회 화면 필드에서 값을 꺼내는 경로를 정하는 규칙.
///
/// **복사 버튼이 유일한 출구여야 한다.** 드래그 선택과 ⌘C가 함께 열려 있으면 그쪽으로 나간 값은
/// `ClipboardCopyPolicy`를 타지 않아 인증도 자동 정리도 반복 감지도 통째로 우회된다.
/// 그래서 선택 허용은 복사 버튼 노출의 정확한 반대다.
///
/// 스크린샷·접근성 API·눈으로 보고 타이핑까지 막지는 못한다. 습관적인 ⌘C가 정책을 비껴가는 것을
/// 막는 것이 목적이고, 화면 캡처는 `isWindowCaptureProtectionEnabled`가 따로 맡는다.
struct DetailFieldCopyAffordance: Equatable {

    /// 복사 버튼을 노출할지.
    let showsCopyButton: Bool

    /// 드래그 선택과 ⌘C를 허용할지.
    var allowsTextSelection: Bool { !showsCopyButton }

    /// - Parameters:
    ///   - isSensitive: 마스킹 대상인지. 복호화 전이라 값이 비어 있어도 빈 값 예외를 적용하지 않는다 —
    ///     비었는지 알 수 없고, 알 수 있는 척하면 마스킹이 값의 존재 여부를 흘린다.
    ///   - isCopyable: 복사 대상 필드인지.
    ///   - value: 현재 값. 평문 필드에서만 빈 값 판정에 쓰인다.
    init(isSensitive: Bool, isCopyable: Bool, value: String) {
        showsCopyButton = isCopyable && (isSensitive || !value.isEmpty)
    }
}
