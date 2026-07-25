// Copyright © 2026 Devault. All rights reserved

import DVDesign
import DVDomain
import SwiftUI

/// `CreatableSecretType.oauth`의 `.oauthClient` 서브타입 폼 섹션.
struct OAuthClientSectionView: View {

    // MARK: - Common Fields

    @Binding var name: String
    @Binding var projectIds: [Project.ID]
    @Binding var service: String
    @Binding var expireDate: Date?
    @Binding var environment: SecretEnvironment
    @Binding var memo: String

    // MARK: - Type-Specific

    /// `OAuthClientFields`: `.clientId`(required) + `.clientSecret`(required) + `.redirectUri` + `.scopes`.
    @Binding var oauthClient: OAuthClientFields

    // MARK: - Context

    let availableProjects: [Project]
    let serviceCandidates: [String]
    let validationErrors: [SecretMetaFields.FieldID: String]
    let detectedServices: [SecretMetaFields.FieldID: String]

    // MARK: - Callbacks

    let onCreateProject: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            NameFieldView(
                name: $name,
                warning: validationErrors[.name]
            )

            LabeledTextFieldView(
                label: .module("Client ID"),
                placeholder: .module("e.g my-app-client"),
                text: $oauthClient.clientId,
                isRequired: true,
                sizeMode: .fullWidth,
                trailingHint: validationErrors[.clientId].map { .warning($0) }
            )

            LabeledTextFieldView(
                label: .module("Client Secret"),
                placeholder: .module("e.g abc123secret"),
                text: $oauthClient.clientSecret,
                isRequired: true,
                sizeMode: .fullWidth,
                trailingHint: hintFor(.clientSecret)
            )

            AdaptiveFieldRow {
                ProjectFieldView(
                    projectIds: $projectIds,
                    availableProjects: availableProjects,
                    onCreateProject: onCreateProject,
                    sizeMode: .paired
                )
            } right: {
                ServicesFieldView(
                    suggestedChips: serviceCandidates,
                    input: $service
                )
            }

            AdaptiveFieldRow {
                ExpireDateFieldView(expireDate: $expireDate)
            } right: {
                EnvironmentFieldView(environment: $environment)
            }

            LabeledTextFieldView(
                label: .module("Redirect URL"),
                placeholder: .module("e.g https://app.example/oauth/callback"),
                text: $oauthClient.redirectUri,
                sizeMode: .fullWidth
            )

            LabeledTextFieldView(
                label: .module("Scope"),
                placeholder: .module("e.g read:user, write:issue"),
                text: $oauthClient.scopes,
                sizeMode: .fullWidth
            )

            MemoFieldView(memo: $memo)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// warning(validation) > detected(감지) 순.
    private func hintFor(_ id: SecretMetaFields.FieldID) -> DVLabeledField<DVTextField>.TrailingHint? {
        if let warning = validationErrors[id] {
            return .warning(warning)
        }
        if let detected = detectedServices[id] {
            return .detected(.module("Auto-detected: \(detected)"))
        }
        return nil
    }
}

// MARK: - Preview

#if DEBUG

private let previewProjects: [Project] = [
    Project(id: UUID(), name: "DrinkiG",     createdAt: Date(), updatedAt: Date()),
    Project(id: UUID(), name: "CheerLot",    createdAt: Date(), updatedAt: Date()),
    Project(id: UUID(), name: "SipStream",   createdAt: Date(), updatedAt: Date()),
]

#Preview("Empty · Dual (Wide)") {
    OAuthClientSectionPreview()
        .padding(24)
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Filled · Dual (Wide)") {
    OAuthClientSectionPreview(
        name: "GitHub OAuth App",
        clientId: "Iv1.abc123",
        clientSecret: "ghs_secret456",
        redirectUri: "https://app.example/oauth/callback",
        scopes: "read:user, write:issue",
        selectedProjectIds: Array(previewProjects.prefix(2).map(\.id)),
        candidates: ["GitHub", "OAuth"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Filled · Single (Narrow)") {
    OAuthClientSectionPreview(
        name: "GitHub OAuth App",
        clientId: "Iv1.abc123",
        clientSecret: "ghs_secret456",
        redirectUri: "https://app.example/oauth/callback",
        scopes: "read:user, write:issue",
        selectedProjectIds: Array(previewProjects.prefix(2).map(\.id)),
        candidates: ["GitHub"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .single)
    .previewWidth(.narrow)
}

#Preview("Validation errors · Dual") {
    OAuthClientSectionPreview(
        errors: [.name: "Required", .clientId: "Required", .clientSecret: "Required"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

private struct OAuthClientSectionPreview: View {

    @State var name: String
    @State var clientId: String
    @State var clientSecret: String
    @State var redirectUri: String
    @State var scopes: String
    @State var projectIds: [Project.ID]
    @State var service: String
    @State var expireDate: Date? = nil
    @State var environment: SecretEnvironment = .staging
    @State var memo: String = ""

    let candidates: [String]
    let errors: [SecretMetaFields.FieldID: String]

    init(
        name: String = "",
        clientId: String = "",
        clientSecret: String = "",
        redirectUri: String = "",
        scopes: String = "",
        selectedProjectIds: [Project.ID] = [],
        service: String = "",
        candidates: [String] = [],
        errors: [SecretMetaFields.FieldID: String] = [:]
    ) {
        _name = State(initialValue: name)
        _clientId = State(initialValue: clientId)
        _clientSecret = State(initialValue: clientSecret)
        _redirectUri = State(initialValue: redirectUri)
        _scopes = State(initialValue: scopes)
        _projectIds = State(initialValue: selectedProjectIds)
        _service = State(initialValue: service)
        self.candidates = candidates
        self.errors = errors
    }

    var body: some View {
        ScrollView {
            OAuthClientSectionView(
                name: $name,
                projectIds: $projectIds,
                service: $service,
                expireDate: $expireDate,
                environment: $environment,
                memo: $memo,
                oauthClient: oauthClientBinding,
                availableProjects: previewProjects,
                serviceCandidates: candidates,
                validationErrors: errors,
                detectedServices: [:],
                onCreateProject: {}
            )
            .padding(16)
        }
    }

    private var oauthClientBinding: Binding<OAuthClientFields> {
        Binding(
            get: {
                OAuthClientFields(
                    clientId: clientId,
                    clientSecret: clientSecret,
                    redirectUri: redirectUri,
                    scopes: scopes
                )
            },
            set: {
                clientId = $0.clientId
                clientSecret = $0.clientSecret
                redirectUri = $0.redirectUri
                scopes = $0.scopes
            }
        )
    }
}

#endif
