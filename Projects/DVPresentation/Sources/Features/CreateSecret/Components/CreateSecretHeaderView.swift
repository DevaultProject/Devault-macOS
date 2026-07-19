// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// CreateSecret 화면 상단 헤더 — SecretType 타이틀 + subtype radio 탭바.
/// `secretType.availableSubTypes`가 비어 있으면 탭바를 렌더링하지 않는다 (database / environmentVariableSet).
/// TCA store에 결합하지 않고 값·콜백만 받아 독립 Preview 가능.
struct CreateSecretHeaderView: View {

    let secretType: CreatableSecretType
    let selectedSubType: CreatableSecretSubType?
    let onSelectSubType: (CreatableSecretSubType) -> Void

    private var subTypes: [CreatableSecretSubType] {
        secretType.availableSubTypes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: subTypes.isEmpty ? 0 : 16) {
            title
            if !subTypes.isEmpty {
                tabBar
            }
        }
    }

    private var title: some View {
        Text(secretType.displayName)
            .dvFont(.headingXL)
            .foregroundStyle(Color.dv(.gray900))
    }

    private var tabBar: some View {
        DVRadioButtonGroup(
            items: subTypes.map {
                .init($0, title: String(localized: $0.displayName))
            },
            selection: Binding(
                get: { selectedSubType ?? subTypes[0] },
                set: { onSelectSubType($0) }
            ),
            size: .md
        )
    }
}

// MARK: - Preview

#Preview("API Keys/Token · 3 subs") {
    CreateSecretHeaderView(
        secretType: .apiKeyToken,
        selectedSubType: .apiKey,
        onSelectSubType: { _ in }
    )
    .previewWidth(.medium)
}

#Preview("OAuth · 2 subs") {
    CreateSecretHeaderView(
        secretType: .oauth,
        selectedSubType: .oauthClient,
        onSelectSubType: { _ in }
    )
    .previewWidth(.medium)
}

#Preview("Database · no tabs") {
    CreateSecretHeaderView(
        secretType: .database,
        selectedSubType: nil,
        onSelectSubType: { _ in }
    )
    .previewWidth(.medium)
}

#Preview("Interactive") {
    InteractiveCreateSecretHeaderPreview(secretType: .apiKeyToken)
        .previewWidth(.medium)
}

private struct InteractiveCreateSecretHeaderPreview: View {

    let secretType: CreatableSecretType
    @State private var selection: CreatableSecretSubType?

    init(secretType: CreatableSecretType) {
        self.secretType = secretType
        self._selection = State(initialValue: secretType.availableSubTypes.first)
    }

    var body: some View {
        CreateSecretHeaderView(
            secretType: secretType,
            selectedSubType: selection,
            onSelectSubType: { selection = $0 }
        )
    }
}
