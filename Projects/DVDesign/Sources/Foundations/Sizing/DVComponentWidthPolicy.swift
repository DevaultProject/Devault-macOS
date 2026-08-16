// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// ``DVComponentSize``를 실제 프레임으로 해석하는 정책.
///
/// 디자인 시스템 컴포넌트는 기본적으로 Figma 스펙의 고정 폭(``DVComponentSize/width``)을 갖습니다.
/// 다만 인스펙터·디테일 페인처럼 **컨테이너 폭이 가변인 자리**에서는 고정 폭이 오른쪽에 큰 여백을
/// 남겨 미완성처럼 보입니다. 그런 맥락에서는 ``fill``을 주입해 컴포넌트가 컨테이너를 채우게 합니다.
///
/// 정책은 Environment로 전파되므로 컴포넌트 호출부를 수정할 필요가 없습니다.
/// 기본값이 ``fixed``이므로 **기존 화면의 동작은 변하지 않습니다.**
///
/// ```swift
/// // 디테일 컬럼처럼 폭이 가변인 화면에서
/// formBody
///     .environment(\.dvComponentWidthPolicy, .fill(minimum: .xs))
/// ```
public enum DVComponentWidthPolicy: Equatable, Sendable {

    /// ``DVComponentSize/width`` 고정. 기본값.
    case fixed

    /// 컨테이너를 채우되 `minimum`보다 좁아지지 않습니다.
    ///
    /// 컨테이너가 좁아지면 컴포넌트도 **1pt 단위로 따라 줄어듭니다** — 토큰 사이를 뛰어넘지 않습니다.
    /// 하한에 닿은 뒤에야 넘치기 시작하므로, 화면은 그 하한만 보장하면 됩니다.
    case fill(minimum: DVComponentSize)
}

extension EnvironmentValues {

    /// 현재 컴포넌트 폭 해석 정책. 기본 ``DVComponentWidthPolicy/fixed``.
    @Entry public var dvComponentWidthPolicy: DVComponentWidthPolicy = .fixed
}

extension View {

    /// ``DVComponentSize``를 현재 ``EnvironmentValues/dvComponentWidthPolicy``에 따라 프레임으로 해석합니다.
    ///
    /// 디자인 시스템 컴포넌트가 `.frame(width: size.width, ...)`를 직접 호출하는 대신 이 modifier를
    /// 사용하면, 호출부가 정책만 주입해 고정 폭 / 가변 폭을 전환할 수 있습니다.
    ///
    /// - Parameters:
    ///   - size: 폭 토큰. `.fixed`에서만 쓰입니다 — `.fill(minimum:)`에서는 컨테이너 폭을 따르므로
    ///     이 값이 결과에 영향을 주지 않습니다.
    ///   - height: 고정 높이. `nil`이면 높이를 제약하지 않습니다.
    ///   - minHeight: 최소 높이. 내용이 많으면 그만큼 **자랍니다**. `height`와 함께 쓰지 않습니다 —
    ///     한쪽은 높이를 묶고 다른 쪽은 풀어주므로 의도가 상충합니다.
    ///   - alignment: 프레임 내 콘텐츠 정렬.
    public func dvComponentWidth(
        _ size: DVComponentSize,
        height: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some View {
        modifier(
            DVComponentWidthModifier(
                size: size,
                height: height,
                minHeight: minHeight,
                alignment: alignment
            )
        )
    }
}

// MARK: - Modifier

private struct DVComponentWidthModifier: ViewModifier {

    @Environment(\.dvComponentWidthPolicy) private var policy

    let size: DVComponentSize
    let height: CGFloat?
    let minHeight: CGFloat?
    let alignment: Alignment

    func body(content: Content) -> some View {
        switch policy {
        case .fixed:
            // minHeight만 준 경우 maxHeight를 열어둬야 내용만큼 자란다.
            content
                .frame(
                    width: size.width,
                    height: height,
                    alignment: alignment
                )
                .frame(minHeight: minHeight, alignment: alignment)
        case .fill(let minimum):
            // 고정 높이는 min/max를 같은 값으로 줘서 표현한다 —
            // `frame(minWidth:maxWidth:height:)` 오버로드는 존재하지 않는다.
            content
                .frame(
                    minWidth: minimum.width,
                    maxWidth: .infinity,
                    minHeight: minHeight ?? height,
                    maxHeight: height,
                    alignment: alignment
                )
        }
    }
}
