// Copyright © 2026 Devault. All rights reserved

import DVDesign
import DVDomain
import SwiftUI

/// `CreatableSecretType.environmentVariableSet` 폼 섹션 (subtype 없음).
/// Figma상 Services / Expire Date 필드 없음 — common 바인딩에서도 제외.
struct EnvSetSectionView: View, CreateSecretSectionHintProviding {

    // MARK: - Common Fields (Services / ExpireDate 없음)

    @Binding var name: String
    @Binding var projectIds: [Project.ID]
    @Binding var environment: SecretEnvironment
    @Binding var memo: String

    // MARK: - Type-Specific

    /// `EnvSetFields`: `.envContent`(required, UI 라벨 "envSet List").
    @Binding var envSet: EnvSetFields

    // MARK: - Context

    let availableProjects: [Project]
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
                label: .module("envSet List"),
                placeholder: .module("e.g FOO=bar"),
                text: $envSet.envContent,
                isRequired: true,
                isSecure: true,
                isMultiline: true,
                sizeMode: .fullWidth,
                trailingHint: hintFor(.envContent)
            )

            AdaptiveFieldRow {
                ProjectFieldView(
                    projectIds: $projectIds,
                    availableProjects: availableProjects,
                    onCreateProject: onCreateProject,
                    sizeMode: .paired
                )
            } right: {
                EnvironmentFieldView(environment: $environment)
            }

        }
    }

}

// MARK: - Preview

#if DEBUG

private let previewProjects: [Project] = [
    Project(id: UUID(), name: "DrinkiG",     createdAt: Date(), updatedAt: Date()),
    Project(id: UUID(), name: "CheerLot",    createdAt: Date(), updatedAt: Date()),
]

#Preview("Empty · Dual (Wide)") {
    EnvSetSectionPreview()
        .padding(24)
        .formLayout(.dual)
        .previewWidth(.wide)
}

#Preview("Filled · Dual (Wide)") {
    EnvSetSectionPreview(
        name: "Backend .env",
        envContent: "DATABASE_URL=postgres://...\nSECRET_KEY=abc123",
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id))
    )
    .padding(24)
    .formLayout(.dual)
    .previewWidth(.wide)
}

#Preview("Filled · Single (Narrow)") {
    EnvSetSectionPreview(
        name: "Backend .env",
        envContent: "DATABASE_URL=postgres://...",
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id))
    )
    .padding(24)
    .formLayout(.single)
    .previewWidth(.narrow)
}

#Preview("Validation errors · Dual") {
    EnvSetSectionPreview(
        errors: [.name: "Required", .envContent: "Required"]
    )
    .padding(24)
    .formLayout(.dual)
    .previewWidth(.wide)
}

private struct EnvSetSectionPreview: View {

    @State var name: String
    @State var envContent: String
    @State var projectIds: [Project.ID]
    @State var environment: SecretEnvironment = .staging
    @State var memo: String = ""

    let errors: [SecretMetaFields.FieldID: String]

    init(
        name: String = "",
        envContent: String = "",
        selectedProjectIds: [Project.ID] = [],
        errors: [SecretMetaFields.FieldID: String] = [:]
    ) {
        _name = State(initialValue: name)
        _envContent = State(initialValue: envContent)
        _projectIds = State(initialValue: selectedProjectIds)
        self.errors = errors
    }

    var body: some View {
        ScrollView {
            EnvSetSectionView(
                name: $name,
                projectIds: $projectIds,
                environment: $environment,
                memo: $memo,
                envSet: envSetBinding,
                availableProjects: previewProjects,
                validationErrors: errors,
                detectedServices: [:],
                onCreateProject: {}
            )
            .padding(16)
        }
    }

    private var envSetBinding: Binding<EnvSetFields> {
        Binding(
            get: { EnvSetFields(envContent: envContent) },
            set: { envContent = $0.envContent }
        )
    }
}

#endif
