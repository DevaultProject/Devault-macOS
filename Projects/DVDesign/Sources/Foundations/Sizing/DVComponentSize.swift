// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// Devault 디자인 시스템의 공통 컴포넌트 사이즈 토큰.
///
/// 입력/표시 계열 컴포넌트(``DVTextField``, ``DVTextContainer`` 등)가
/// Figma 스펙의 4 단계 너비 변형을 동일한 어휘로 표현하기 위해 공유하는
/// enum입니다. 각 케이스는 ``width`` 프로퍼티로 디자인에서 정의된 고정
/// 가로 크기(포인트)를 제공합니다.
///
/// ## Usage
///
/// ```swift
/// DVTextField("e.g DeVault", text: $value, size: .md)
/// DVTextContainer("DeVault", size: .lg)
/// ```
///
/// ## Variables
///
/// | 케이스 | 너비 |
/// |--------|-----|
/// | ``xs`` | 180pt |
/// | ``sm`` | 330pt |
/// | ``md`` | 380pt |
/// | ``lg`` | 700pt |
public enum DVComponentSize: CaseIterable {
    case xs

    case sm

    case md

    case lg

    /// 디자인 스펙에 정의된 가로 크기
    public var width: CGFloat {
        switch self {
        case .xs: return 180
        case .sm: return 330
        case .md: return 380
        case .lg: return 700
        }
    }
}
