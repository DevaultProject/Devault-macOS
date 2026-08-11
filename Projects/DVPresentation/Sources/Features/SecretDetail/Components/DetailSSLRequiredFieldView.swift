// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

/// 조회 화면의 "SSL Required" 필드 — 생성 화면 `SSLRequiredFieldView`의 read-only 대응.
///
/// 값이 Bool이라 텍스트(`DetailReadOnlyFieldView`)가 아니라 읽기 전용 체크박스로 표시한다.
/// 생성 화면이 체크박스로 입력받는 값을 조회 화면에서 "Required" 같은 문자열로 바꿔 보여주면
/// 두 화면의 표현이 어긋나기 때문이다. 라벨·간격도 생성 화면과 같은 값을 쓴다.
struct DetailSSLRequiredFieldView: View {

    let isRequired: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(.module("SSL Required"))
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.gray700))
            DVCheckBox(readOnly: isRequired)
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Required") {
    DetailSSLRequiredFieldView(isRequired: true)
        .padding()
        .previewWidth(420)
}

#Preview("Not Required") {
    DetailSSLRequiredFieldView(isRequired: false)
        .padding()
        .previewWidth(420)
}

#endif
