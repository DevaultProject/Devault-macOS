// Copyright © 2026 Devault. All rights reserved

import SwiftUI

extension View {
    /// `DVFont` 토큰을 line-height까지 함께 적용한다.
    /// 디자인 시스템과 정렬된 타이포그래피를 위해 `.font(...)` 대신 이 modifier를 사용한다.
    public func dvFont(_ token: DVFont) -> some View {
        self
            .font(token.font)
            .lineSpacing(token.lineSpacing)
            .padding(.vertical, token.lineSpacing / 2)
    }
}
