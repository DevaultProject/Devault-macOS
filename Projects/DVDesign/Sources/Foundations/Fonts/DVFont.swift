// Copyright © 2026 Devault. All rights reserved

import AppKit
import SwiftUI

public enum DVFont: CaseIterable {
    case displayBrand

    case headingXL
    case headingLG

    case bodyXL
    case bodyLG
    case bodyMD

    case captionLG
    case captionMDSemibold
    case captionMDRegular

    public var size: CGFloat {
        switch self {
        case .displayBrand:      return 28
        case .headingXL:         return 22
        case .headingLG:         return 18
        case .bodyXL:            return 16
        case .bodyLG:            return 15
        case .bodyMD:            return 13
        case .captionLG:         return 12
        case .captionMDSemibold: return 11
        case .captionMDRegular:  return 11
        }
    }

    public var weight: Font.Weight {
        switch self {
        case .displayBrand:
            return .bold
        case .headingXL, .headingLG, .captionLG, .captionMDSemibold:
            return .semibold
        case .bodyXL, .bodyLG, .bodyMD:
            return .medium
        case .captionMDRegular:
            return .regular
        }
    }

    /// 디자인 스펙에 정의된 line-height 비율 (예: 1.14 == 114%)
    public var lineHeightRatio: CGFloat {
        switch self {
        case .displayBrand:      return 1.14
        case .headingXL:         return 1.36
        case .headingLG:         return 1.11
        case .bodyXL:            return 1.20
        case .bodyLG:            return 1.06
        case .bodyMD:            return 1.23
        case .captionLG:         return 1.19
        case .captionMDSemibold: return 1.18
        case .captionMDRegular:  return 1.18
        }
    }

    /// 실제 line-height 값 (size × ratio, 단위: pt)
    public var lineHeight: CGFloat {
        size * lineHeightRatio
    }

    /// 멀티라인 텍스트가 `lineHeight`에 맞도록 SwiftUI `.lineSpacing`에 넘길 추가 간격
    public var lineSpacing: CGFloat {
        max(lineHeight - size, 0)
    }

    public var font: Font {
        .system(size: size, weight: weight)
    }

    /// `NSView`를 직접 쓰는 자리에 넘길 폰트. 굵기는 ``weight``에서 옮겨오므로 갈리지 않는다.
    public var nsFont: NSFont {
        .systemFont(ofSize: size, weight: Self.nsWeight(weight))
    }

    private static func nsWeight(_ weight: Font.Weight) -> NSFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        default:          return .regular
        }
    }
}
