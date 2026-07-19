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
    }
}

// MARK: - Subviews

extension CreateSecretView {

    /// FIXED TOP. subtype 탭 바 포함 예정.
    private var header: some View {
        placeholderBar(label: "Header", height: 64)
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

    private func placeholderBar(label: String, height: CGFloat) -> some View {
        Text("\(label) — TBD")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color.gray.opacity(0.12))
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
