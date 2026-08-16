// Copyright © 2026 Devault. All rights reserved

import AppKit
import SwiftUI

public enum DVColor: CaseIterable {
    case vaultGreen
    case vaultGreenDark
    case vaultGreenTint
    case vaultDark
    case gray900
    case gray800
    case gray700
    case gray600
    case gray500
    case gray400
    case gray300
    case gray200
    case gray100
    case white
    case black
    case danger
    case warning
    case required

    /// Asset catalog에 등록된 이름. `color`와 `nsColor`가 공유해 두 벌로 갈리지 않게 한다.
    private var assetName: String {
        switch self {
        case .vaultGreen:      return "vault green"
        case .vaultGreenDark:  return "vault green dark"
        case .vaultGreenTint:  return "vault green tint"
        case .vaultDark:       return "vault dark"
        case .gray900:         return "gray900"
        case .gray800:         return "gray800"
        case .gray700:         return "gray700"
        case .gray600:         return "gray600"
        case .gray500:         return "gray500"
        case .gray400:         return "gray400"
        case .gray300:         return "gray300"
        case .gray200:         return "gray200"
        case .gray100:         return "gray100"
        case .white:           return "white"
        case .black:           return "black"
        case .danger:          return "danger"
        case .warning:         return "warning"
        case .required:        return "required"
        }
    }

    public var color: Color {
        Color(assetName, bundle: .module)
    }

    /// `NSView`를 직접 쓰는 자리에 넘길 색. `color`와 같은 asset을 가리킨다.
    public var nsColor: NSColor {
        NSColor(named: assetName, bundle: .module) ?? .labelColor
    }
}
