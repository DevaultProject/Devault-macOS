// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// Database 서브뷰 전용 "SSL Required" 체크박스 필드.
/// `DatabaseFields.sslRequired`에 바인딩. 라벨과 체크박스를 인라인 배치.
struct SSLRequiredFieldView: View {

    @Binding var isChecked: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text("SSL Required")
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.gray700))
            DVCheckBox(isChecked: isChecked) { isChecked.toggle() }
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Off") {
    SSLRequiredFieldPreview(initial: false)
        .padding()
        .previewWidth(.medium)
}

#Preview("On") {
    SSLRequiredFieldPreview(initial: true)
        .padding()
        .previewWidth(.medium)
}

private struct SSLRequiredFieldPreview: View {
    @State private var isChecked: Bool

    init(initial: Bool) {
        _isChecked = State(initialValue: initial)
    }

    var body: some View {
        SSLRequiredFieldView(isChecked: $isChecked)
    }
}

#endif
