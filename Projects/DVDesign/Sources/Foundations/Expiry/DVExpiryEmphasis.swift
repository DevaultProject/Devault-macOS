// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 만료 임박을 시각적으로 강조하는 단계.
///
/// **며칠 이내를 어느 단계로 볼지는 소비 모듈의 정책이다.** 디자인 시스템은 단계별 표현
/// (아이콘 · 색 토큰)만 소유한다. 목록 행(``DVVaultContainer``)과 조회 필드(``DVTextContainer``)가
/// 이 하나를 함께 참조하므로, 같은 만료 상태가 화면마다 다른 모습으로 그려질 수 없다.
///
/// 케이스 이름이 색 토큰과 같은 것은 의도된 것이다 — 단계의 의미(만료됨 / N일 이내)는
/// 정책을 가진 쪽에 있고, 여기엔 "어느 세기로 그리는가"만 남는다.
public enum DVExpiryEmphasis: CaseIterable, Sendable {

    /// 즉시 조치가 필요한 단계 — 경고 삼각형 + ``DVColor/danger``.
    case danger

    /// 예고 단계 — 캘린더 + ``DVColor/warning``.
    case warning

    /// 단계를 나타내는 SF Symbol.
    public var icon: Image {
        Image(systemName: iconName)
    }

    /// 아이콘과 그에 딸린 텍스트에 **함께** 적용하는 색 토큰 — 디자인이 둘을 같은 색으로 칠한다.
    public var colorToken: DVColor {
        switch self {
        case .danger:  return .danger
        case .warning: return .warning
        }
    }

    private var iconName: String {
        switch self {
        case .danger:  return "exclamationmark.triangle"
        case .warning: return "calendar"
        }
    }
}
