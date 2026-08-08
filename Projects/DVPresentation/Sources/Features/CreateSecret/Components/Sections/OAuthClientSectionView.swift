// Copyright © 2026 Devault. All rights reserved

import DVDesign
import DVDomain
import SwiftUI

/// `CreatableSecretType.oauth`의 `.oauthClient` 서브타입 폼 섹션.
struct OAuthClientSectionView: View, CreateSecretSectionHintProviding {

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
        FormSectionScaffold(
            name: $name,
            nameWarning: validationErrors[.name],
            memo: $memo
        ) {
            LabeledTextFieldView(
                label: .module("Client ID"),
                placeholder: .module("e.g my-app-client"),
                text: $oauthClient.clientId,
                isRequired: true,
                sizeMode: .fullWidth,
                trailingHint: hintFor(.clientId)
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

        }
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
        .formLayout(.dual)
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
    .formLayout(.dual)
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
    .formLayout(.single)
    .previewWidth(.narrow)
}

#Preview("Validation errors · Dual") {
    OAuthClientSectionPreview(
        errors: [.name: "Required", .clientId: "Required", .clientSecret: "Required"]
    )
    .padding(24)
    .formLayout(.dual)
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
