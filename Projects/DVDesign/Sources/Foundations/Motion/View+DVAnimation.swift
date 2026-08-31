// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public extension View {
    /// `.animation(_:value:)`의 reduce-motion 인식 버전.
    ///
    /// 시스템 "동작 줄이기(Reduce Motion)"가 켜져 있으면 애니메이션을 생략해 즉시 전환한다.
    /// 위치·크기가 움직이는 레이아웃·화면 전환 애니메이션은 이 모디파이어를 통해 걸어 접근성 대응을 한 곳에서 관리한다.
    /// hover 색상 피드백처럼 vestibular 움직임이 아닌 것은 그냥 `.animation`으로 두어 제외한다.
    func dvAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(ReduceMotionAnimation(animation: animation, value: value))
    }
}

private struct ReduceMotionAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}
