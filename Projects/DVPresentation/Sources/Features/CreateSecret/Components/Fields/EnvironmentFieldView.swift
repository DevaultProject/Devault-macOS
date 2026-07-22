// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// CreateSecret 폼의 Environment 필드 (dev / staging / prod 라디오).
/// `SecretMetaFields.environment`에 바인딩. 항상 `paired` 슬롯에 배치되므로 sizeMode 파라미터 없음.
struct EnvironmentFieldView: View {

    @Binding var environment: SecretEnvironment

    @Environment(\.formLayoutMode) private var mode

    private var size: DVComponentSize { mode.pairedFieldSize }

    var body: some View {
        DVLabeledField("Environment", size: size) {
            DVRadioButtonGroup(
                items: SecretEnvironment.allCases.map {
                    .init($0, title: String(localized: $0.displayName))
                },
                selection: $environment,
                size: .sm
            )
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Dual · dev selected") {
    EnvironmentFieldPreview(initial: .dev)
        .padding()
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Dual · staging selected") {
    EnvironmentFieldPreview(initial: .staging)
        .padding()
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Single · prod selected") {
    EnvironmentFieldPreview(initial: .prod)
        .padding()
        .environment(\.formLayoutMode, .single)
        .previewWidth(.narrow)
}

private struct EnvironmentFieldPreview: View {
    @State private var env: SecretEnvironment

    init(initial: SecretEnvironment) {
        _env = State(initialValue: initial)
    }

    var body: some View {
        EnvironmentFieldView(environment: $env)
    }
}

#endif
