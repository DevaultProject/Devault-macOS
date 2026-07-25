// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import SwiftUI

// MARK: - CreateSecretView

struct CreateSecretView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<CreateSecretFeature>

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            scrollContent
            footer
        }
        .task { await store.send(.task).finish() }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $store.scope(state: \.createProject, action: \.createProject)) { store in
            CreateProjectView(store: store)
        }
    }
}

// MARK: - Subviews

extension CreateSecretView {

    /// FIXED TOP. SecretType 타이틀 + subtype radio 탭바.
    private var header: some View {
        CreateSecretHeaderView(
            secretType: store.secretType,
            selectedSubType: store.selectedSubType,
            onSelectSubType: { subType in
                store.send(.set(\.selectedSubType, subType))
            }
        )
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    /// 중간 스크롤 영역. CommonMetaSection · TypeSpecific 서브뷰가 들어갈 자리.
    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<24, id: \.self) { index in
                    Text("Placeholder row \(index)")
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.05))
                }
            }
            .padding(16)
        }
    }

    /// FIXED BOTTOM. Cancel + Save 액션 바.
    private var footer: some View {
        FooterActionsView(
            isSaveEnabled: store.isSaveEnabled,
            onCancel: { store.send(.didTapCancel) },
            onSave: { store.send(.didTapSave) }
        )
    }

}

// MARK: - Preview

#Preview("Narrow · 360pt") {
    CreateSecretView(
        store: Store(initialState: .init(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        }
    )
    .previewWidth(.narrow)
}

#Preview("Medium · 560pt") {
    CreateSecretView(
        store: Store(initialState: .init(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        }
    )
    .previewWidth(.medium)
}

#Preview("Wide · 820pt") {
    CreateSecretView(
        store: Store(initialState: .init(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        }
    )
    .previewWidth(.wide)
}

#Preview("Database · no subs · Medium") {
    CreateSecretView(
        store: Store(initialState: .init(secretType: .database)) {
            CreateSecretFeature()
        }
    )
    .previewWidth(.medium)
}
