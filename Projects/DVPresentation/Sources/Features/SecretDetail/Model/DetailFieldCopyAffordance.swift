// Copyright © 2026 Devault. All rights reserved

/// 조회 화면 필드에서 값을 꺼내는 경로를 정하는 규칙.
///
/// **민감 필드는 복사 버튼만 출구로 둔다.** 드래그 선택과 ⌘C가 열려 있으면 그 값이
/// `ClipboardCopyPolicy.sensitive`를 타지 않아 인증·자동 정리·반복 감지가 통째로 우회된다.
/// 평문 필드는 `.plain`이 세 정책 다 꺼진 채로 가므로 막아도 지킬 것이 없어 열어둔다.
///
/// 기준이 `isCopyable`이 아니라 `isSensitive`인 이유는, 복사 버튼에 묶으면 민감하지만 복사
/// 대상이 아닌 필드에서 선택이 열리기 때문이다 — 눈 토글은 `isCopyable`과 무관하게 살아 있다.
///
/// 습관적인 ⌘C만 막는다. 화면 캡처는 `isWindowCaptureProtectionEnabled`가 따로 맡는다.
struct DetailFieldCopyAffordance: Equatable {

    /// 복사 버튼을 노출할지.
    let showsCopyButton: Bool

    /// 드래그 선택과 ⌘C를 허용할지.
    let allowsTextSelection: Bool

    /// - Parameters:
    ///   - isSensitive: 마스킹 대상인지. 복호화 전이라 비었는지 알 수 없어 빈 값 예외를 적용하지
    ///     않는다 — 아는 척하면 마스킹이 값의 존재 여부를 흘린다.
    ///   - isCopyable: 복사 대상 필드인지.
    ///   - value: 현재 값. 평문 필드의 빈 값 판정에만 쓰인다.
    init(isSensitive: Bool, isCopyable: Bool, value: String) {
        showsCopyButton = isCopyable && (isSensitive || !value.isEmpty)
        allowsTextSelection = !isSensitive
    }
}
