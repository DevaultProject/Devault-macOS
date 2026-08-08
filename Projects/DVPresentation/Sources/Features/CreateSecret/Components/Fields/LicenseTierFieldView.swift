// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// CreateSecret 폼의 License Tier 필드 (individual / team / enterprise 라디오).
/// LicenseKey 서브타입 전용. Figma 라벨은 "Type" (LicenseTier 명명은 모델 내부용).
/// `LicenseKeyFields.licenseTier`에 바인딩. 항상 `paired` 슬롯에 배치.
struct LicenseTierFieldView: View {

    @Binding var tier: LicenseTier

    @Environment(\.formLayout) private var layout

    private var size: DVComponentSize { layout.size(for: .paired) }

    var body: some View {
        DVLabeledField(.module("Type"), size: size) {
            DVRadioButtonGroup(
                items: LicenseTier.allCases.map {
                    .init($0, title: String(localized: $0.displayName))
                },
                selection: $tier,
                size: .sm
            )
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Dual · Individual") {
    LicenseTierFieldPreview(initial: .individual)
        .padding()
        .formLayout(.dual)
        .previewWidth(.wide)
}

#Preview("Dual · Team") {
    LicenseTierFieldPreview(initial: .team)
        .padding()
        .formLayout(.dual)
        .previewWidth(.wide)
}

#Preview("Single · Enterprise") {
    LicenseTierFieldPreview(initial: .enterprise)
        .padding()
        .formLayout(.single)
        .previewWidth(.narrow)
}

private struct LicenseTierFieldPreview: View {
    @State private var tier: LicenseTier

    init(initial: LicenseTier) {
        _tier = State(initialValue: initial)
    }

    var body: some View {
        LicenseTierFieldView(tier: $tier)
    }
}

#endif
