// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import SwiftUI

// MARK: - CreateSecretView

struct CreateSecretView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<CreateSecretFeature>

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            header
            scrollContent
            footer
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
    }

    /// 중간 스크롤 영역. secretType에 따라 대응 SectionView로 분기.
    private var scrollContent: some View {
        ScrollView {
            typeSpecificSection
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var typeSpecificSection: some View {
        switch store.secretType {
        case .apiKeyToken:
            APIKeysTokenSectionView(
                name: $store.meta.name,
                projectIds: $store.meta.projectIds,
                service: $store.meta.service,
                expireDate: $store.meta.expireDate,
                environment: $store.meta.environment,
                memo: $store.meta.memo,
                apiKeyToken: $store.meta.content.typed(\.apiKeyToken, default: APIKeyTokenFields()),
                availableProjects: store.availableProjects,
                serviceCandidates: store.serviceCandidates,
                validationErrors: store.validationErrors,
                detectedServices: store.detectedServices,
                onCreateProject: { store.send(.didTapCreateProject) }
            )

        case .oauth:
            oauthSection

        default:
            // TODO(#41-followup): 나머지 SecretType별 SectionView 추가 (database/ssh/env/etc).
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<8, id: \.self) { index in
                    Text("Placeholder row \(index) — \(String(describing: store.secretType))")
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.05))
                }
            }
        }
    }

    /// OAuth는 2개 subtype(oauthClient / serviceAccount)이 서로 다른 필드 구성 —
    /// SectionView를 분리하고 selectedSubType으로 분기.
    @ViewBuilder
    private var oauthSection: some View {
        switch store.selectedSubType {
        case .oauthClient:
            OAuthClientSectionView(
                name: $store.meta.name,
                projectIds: $store.meta.projectIds,
                service: $store.meta.service,
                expireDate: $store.meta.expireDate,
                environment: $store.meta.environment,
                memo: $store.meta.memo,
                oauthClient: $store.meta.content.typed(\.oauthClient, default: OAuthClientFields()),
                availableProjects: store.availableProjects,
                serviceCandidates: store.serviceCandidates,
                validationErrors: store.validationErrors,
                detectedServices: store.detectedServices,
                onCreateProject: { store.send(.didTapCreateProject) }
            )

        case .serviceAccount:
            ServiceAccountSectionView(
                name: $store.meta.name,
                projectIds: $store.meta.projectIds,
                service: $store.meta.service,
                expireDate: $store.meta.expireDate,
                memo: $store.meta.memo,
                serviceAccount: $store.meta.content.typed(\.serviceAccount, default: ServiceAccountFields()),
                availableProjects: store.availableProjects,
                serviceCandidates: store.serviceCandidates,
                validationErrors: store.validationErrors,
                detectedServices: store.detectedServices,
                onCreateProject: { store.send(.didTapCreateProject) }
            )

        default:
            EmptyView()
        }
    }


    /// FIXED BOTTOM. Cancel + Save 액션 바.
    private var footer: some View {
        FooterActionsView(
            isSaveEnabled: store.isSaveEnabled,
            onCancel: { store.send(.didTapCancel) },
            onSave: { store.send(.didTapSave) }
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

}

// MARK: - Preview

#if DEBUG

private func previewState(
    fill: Bool = false,
    withProjects: Bool = false
) -> CreateSecretFeature.State {
    var state = CreateSecretFeature.State(secretType: .apiKeyToken)
    if withProjects {
        let seed: [Project] = [
            Project(id: UUID(), name: "DrinkiG", createdAt: Date(), updatedAt: Date()),
            Project(id: UUID(), name: "Longlonglong Project Name", createdAt: Date(), updatedAt: Date()),
            Project(id: UUID(), name: "CheerLot", createdAt: Date(), updatedAt: Date()),
            Project(id: UUID(), name: "SipStream", createdAt: Date(), updatedAt: Date()),
        ]
        state.availableProjects = seed
        state.meta.projectIds = Array(seed.prefix(2).map(\.id))
        state.serviceCandidates = ["GitHub", "NameNameName"]
    }
    if fill {
        state.meta.name = "GitHub Access Token"
        state.meta.content = .apiKeyToken(APIKeyTokenFields(value: "ghp_1234567890", authorityScope: "repo:read"))
        state.detectedServices = [.value: "GitHub"]
    }
    return state
}

#Preview("Wide · Empty (Dual)") {
    CreateSecretView(
        store: Store(initialState: previewState()) {
            CreateSecretFeature()
        }
    )
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Wide · Filled + hint (Dual)") {
    CreateSecretView(
        store: Store(initialState: previewState(fill: true, withProjects: true)) {
            CreateSecretFeature()
        }
    )
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Narrow · Filled (Single, scrollable)") {
    CreateSecretView(
        store: Store(initialState: previewState(fill: true, withProjects: true)) {
            CreateSecretFeature()
        }
    )
    .environment(\.formLayoutMode, .single)
    .previewWidth(.narrow)
    .frame(height: 700)
}

#Preview("Medium · Empty (Single)") {
    CreateSecretView(
        store: Store(initialState: previewState()) {
            CreateSecretFeature()
        }
    )
    .environment(\.formLayoutMode, .single)
    .previewWidth(.medium)
}

#Preview("OAuth Client · Wide (Dual)") {
    CreateSecretView(
        store: Store(initialState: oauthPreviewState(subType: .oauthClient, fill: true)) {
            CreateSecretFeature()
        }
    )
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("OAuth Client · Narrow (Single, scrollable)") {
    CreateSecretView(
        store: Store(initialState: oauthPreviewState(subType: .oauthClient, fill: true)) {
            CreateSecretFeature()
        }
    )
    .environment(\.formLayoutMode, .single)
    .previewWidth(.narrow)
    .frame(height: 700)
}

#Preview("Service Account · Wide (Dual)") {
    CreateSecretView(
        store: Store(initialState: oauthPreviewState(subType: .serviceAccount, fill: true)) {
            CreateSecretFeature()
        }
    )
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Service Account · Narrow (Single)") {
    CreateSecretView(
        store: Store(initialState: oauthPreviewState(subType: .serviceAccount, fill: true)) {
            CreateSecretFeature()
        }
    )
    .environment(\.formLayoutMode, .single)
    .previewWidth(.narrow)
    .frame(height: 700)
}

#Preview("Database · placeholder (다른 타입 임시)") {
    CreateSecretView(
        store: Store(initialState: .init(secretType: .database)) {
            CreateSecretFeature()
        }
    )
    .previewWidth(.medium)
}

private func oauthPreviewState(
    subType: CreatableSecretSubType,
    fill: Bool = false
) -> CreateSecretFeature.State {
    var state = CreateSecretFeature.State(secretType: .oauth)
    state.selectedSubType = subType

    let seed: [Project] = [
        Project(id: UUID(), name: "DrinkiG", createdAt: Date(), updatedAt: Date()),
        Project(id: UUID(), name: "CheerLot", createdAt: Date(), updatedAt: Date()),
    ]
    state.availableProjects = seed
    state.meta.projectIds = Array(seed.prefix(1).map(\.id))

    guard fill else {
        state.meta.content = .default(for: .oauth, subType: subType)
        return state
    }

    state.meta.name = "Sample OAuth Secret"
    switch subType {
    case .oauthClient:
        state.meta.content = .oauthClient(
            OAuthClientFields(
                clientId: "Iv1.abc123",
                clientSecret: "ghs_secret456",
                redirectUri: "https://app.example/oauth/callback",
                scopes: "read:user, write:issue"
            )
        )
    case .serviceAccount:
        state.meta.content = .serviceAccount(
            ServiceAccountFields(
                credentialJSON: #"{"type": "service_account", "project_id": "my-proj"}"#,
                authority: "organization-admin"
            )
        )
    default:
        state.meta.content = .default(for: .oauth, subType: subType)
    }
    return state
}

#endif
