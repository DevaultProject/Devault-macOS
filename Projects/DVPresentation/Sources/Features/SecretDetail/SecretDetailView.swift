// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign
import DVDomain

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
        .alert($store.scope(state: \.alert, action: \.alert))
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
                // 편집 모드는 후속 이슈에서 구현한다. 상태 전이가 없는 동안
                // 눌러도 반응하지 않는 컨트롤을 노출하지 않기 위해 Edit 버튼을 숨긴다.
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            Divider()
        }
    }

    // MARK: Viewing

    /// 현재는 name만 노출하는 뼈대다. 후속 이슈에서 `store.payloadState`의
    /// loading / loaded / failed를 분기하고, loaded에서 `CreateSecretPayload`
    /// 유형별 필드와 `store.secret` 메타 정보를 렌더링한다.
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

    // MARK: Editing

    /// 편집 모드 진입 경로가 아직 없어 도달하지 않는다. 후속 이슈에서
    /// `editFields` 바인딩과 SectionView 재사용으로 채운다.
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
