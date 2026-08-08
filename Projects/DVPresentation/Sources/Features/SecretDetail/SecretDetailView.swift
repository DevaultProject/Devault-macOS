// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDesign
import DVDomain
import SwiftUI

// MARK: - SecretDetailView

public struct SecretDetailView: View {

    // MARK: - Properties

    @Bindable public var store: StoreOf<SecretDetailFeature>

    // MARK: - Init

    public init(store: StoreOf<SecretDetailFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            topBar
            Group {
                if store.mode == .viewing {
                    viewingBody
                } else {
                    editingBody
                }
            }
            if store.mode == .editing {
                // Issue C에서 FooterActionsView 연결
                Divider()
                HStack {
                    Spacer()
                    Button("Cancel") { store.send(.didTapCancelEdit) }
                        .buttonStyle(.plain)
                    Button("Save") { store.send(.didTapSave) }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .task { store.send(.task) }
    }
}

// MARK: - Subviews

extension SecretDetailView {

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button { store.send(.didTapClose) } label: {
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
                Spacer()
                if store.mode == .viewing {
                    Button { store.send(.didTapEdit) } label: {
                        Image(systemName: "pencil")
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            Divider()
        }
    }

    // MARK: Viewing — 인터랙티브 컨트롤 완전 배제 (Issue B에서 완성)

    @ViewBuilder
    private var viewingBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(store.secret.name)
                    .dvFont(.headingLG)
                    .foregroundStyle(Color.dv(.gray900))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
        }
    }

    // MARK: Editing — CreateSecret SectionView 재사용 (Issue C에서 완성)

    @ViewBuilder
    private var editingBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(store.secret.name)
                    .dvFont(.headingLG)
                    .foregroundStyle(Color.dv(.gray900))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG

private let _previewSecret = Secret(
    id: UUID(),
    name: "GitHub Personal Token",
    secretType: .apiKeyToken,
    service: "GitHub",
    environment: "production",
    createdAt: Date(),
    updatedAt: Date(),
    payload: SecretPayload(encryptedData: Data(), keyTag: "preview", schemaVersion: 1)
)

#Preview("SecretDetail · Viewing") {
    SecretDetailView(
        store: Store(
            initialState: SecretDetailFeature.State(secret: _previewSecret)
        ) {
            SecretDetailFeature()
        }
    )
    .frame(width: 420, height: 700)
}

#Preview("SecretDetail · Editing") {
    SecretDetailView(
        store: Store(
            initialState: {
                var state = SecretDetailFeature.State(secret: _previewSecret)
                state.mode = .editing
                return state
            }()
        ) {
            SecretDetailFeature()
        }
    )
    .frame(width: 420, height: 700)
}

#endif
