// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// CreateSecret 폼의 컨테이너 폭에 따라 2-column vs 1-column 레이아웃을 결정하는 모드.
///
/// 상위 뷰(`CreateSecretView`)가 `GeometryReader`로 폭을 측정해 `mode(for:)`로 계산 후
/// Environment(`\.formLayoutMode`)에 주입한다. 하위 뷰들(`AdaptiveFieldRow`, 각 Field 뷰)은
/// Environment를 읽어 **같은 판단**으로 자기 레이아웃/사이즈를 결정한다 —
/// 각 row가 독립적으로 판단해서 서로 다른 결과가 나오는 사고 방지.
///
/// TODO(#41-followup): `CreateSecretView.body`에 `GeometryReader` + `.environment(\.formLayoutMode, ...)` 주입 wiring 필요.
/// 현재는 default `.dual`이 하위 뷰에 흘러가고 있음 (반응형 동작 안 함).
enum FormLayoutMode: Equatable {

    /// 2-column row 가능. 컨테이너 폭이 임계값 이상일 때.
    case dual

    /// 1-column stack. 2-col row가 VStack으로 접히고 full-width 필드는 사이즈 축소.
    case single

    /// dual 모드로 전환하는 최소 컨테이너 폭.
    ///
    /// 계산: `2 × DVComponentSize.md(380) + column gap(20) + horizontal padding(24 × 2)`
    /// = `828pt`.
    static let dualThreshold: CGFloat = 828

    /// 컨테이너 폭에 대응하는 모드 계산.
    static func mode(for containerWidth: CGFloat) -> FormLayoutMode {
        containerWidth >= dualThreshold ? .dual : .single
    }

    /// full-width 필드(Name/Value/Memo 등)가 취할 컴포넌트 사이즈.
    /// dual에서 `.lg`(700), single에서 `.md`(380)로 축소.
    var fullWidthFieldSize: DVComponentSize {
        switch self {
        case .dual:   return .lg
        case .single: return .md
        }
    }

    /// 2-col row 안에 배치되는 필드(Project/Services/ExpireDate 등)가 취할 컴포넌트 사이즈.
    /// 두 모드 모두 `.md`(380) — 사이즈는 그대로 두고 layout만 전환.
    var pairedFieldSize: DVComponentSize { .md }
}

extension EnvironmentValues {

    /// 현재 폼 레이아웃 모드. 기본 `.dual`.
    /// `CreateSecretView`가 `GeometryReader`로 계산해 명시적으로 주입한다.
    @Entry var formLayoutMode: FormLayoutMode = .dual
}
