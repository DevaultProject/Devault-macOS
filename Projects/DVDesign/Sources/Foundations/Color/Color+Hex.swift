// Copyright © 2026 Devault. All rights reserved

import SwiftUI

extension Color {
    /// 0xRRGGBB 형식의 브랜드 컬러 하드코딩(예: 서비스 로고 색상)에 쓴다.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
