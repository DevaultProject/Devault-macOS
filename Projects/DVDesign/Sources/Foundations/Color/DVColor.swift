// Copyright © 2026 Devault. All rights reserved

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

    public var color: Color {
        switch self {
        case .vaultGreen:      return Color("vault green", bundle: .module)
        case .vaultGreenDark:  return Color("vault green dark", bundle: .module)
        case .vaultGreenTint:  return Color("vault green tint", bundle: .module)
        case .vaultDark:       return Color("vault dark", bundle: .module)
        case .gray900:         return Color("gray900", bundle: .module)
        case .gray800:         return Color("gray800", bundle: .module)
        case .gray700:         return Color("gray700", bundle: .module)
        case .gray600:         return Color("gray600", bundle: .module)
        case .gray500:         return Color("gray500", bundle: .module)
        case .gray400:         return Color("gray400", bundle: .module)
        case .gray300:         return Color("gray300", bundle: .module)
        case .gray200:         return Color("gray200", bundle: .module)
        case .gray100:         return Color("gray100", bundle: .module)
        case .white:           return Color("white", bundle: .module)
        case .black:           return Color("black", bundle: .module)
        case .danger:          return Color("danger", bundle: .module)
        case .warning:         return Color("warning", bundle: .module)
        }
    }
}
