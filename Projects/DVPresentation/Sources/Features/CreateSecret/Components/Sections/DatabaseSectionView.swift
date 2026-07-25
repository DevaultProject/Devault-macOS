// Copyright © 2026 Devault. All rights reserved

import DVDesign
import DVDomain
import SwiftUI

/// `CreatableSecretType.database` 폼 섹션 (subtype 없음).
struct DatabaseSectionView: View, CreateSecretSectionHintProviding {

    // MARK: - Common Fields

    @Binding var name: String
    @Binding var projectIds: [Project.ID]
    @Binding var service: String
    @Binding var expireDate: Date?
    @Binding var environment: SecretEnvironment
    @Binding var memo: String

    // MARK: - Type-Specific

    /// `DatabaseFields`: `.linkString`(required) + `.isSSLRequired`(Bool).
    @Binding var database: DatabaseFields

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
                label: .module("Link String"),
                placeholder: .module("e.g postgres://user:pass@host:5432/db"),
                text: $database.linkString,
                isRequired: true,
                sizeMode: .fullWidth,
                trailingHint: hintFor(.linkString)
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

            SSLRequiredFieldView(isChecked: $database.isSSLRequired)

            MemoFieldView(memo: $memo)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    DatabaseSectionPreview()
        .padding(24)
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Filled · Dual (Wide)") {
    DatabaseSectionPreview(
        name: "Production PostgreSQL",
        linkString: "postgres://user:pass@db.example.com:5432/main",
        isSSLRequired: true,
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id)),
        candidates: ["postgres", "db"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Filled · Single (Narrow)") {
    DatabaseSectionPreview(
        name: "Production PostgreSQL",
        linkString: "postgres://user:pass@db.example.com:5432/main",
        isSSLRequired: true,
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id)),
        candidates: ["postgres"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .single)
    .previewWidth(.narrow)
}

#Preview("Validation errors · Dual") {
    DatabaseSectionPreview(
        errors: [.name: "Required", .linkString: "Required"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

private struct DatabaseSectionPreview: View {

    @State var name: String
    @State var linkString: String
    @State var isSSLRequired: Bool
    @State var projectIds: [Project.ID]
    @State var service: String
    @State var expireDate: Date? = nil
    @State var environment: SecretEnvironment = .staging
    @State var memo: String = ""

    let candidates: [String]
    let errors: [SecretMetaFields.FieldID: String]

    init(
        name: String = "",
        linkString: String = "",
        isSSLRequired: Bool = false,
        selectedProjectIds: [Project.ID] = [],
        service: String = "",
        candidates: [String] = [],
        errors: [SecretMetaFields.FieldID: String] = [:]
    ) {
        _name = State(initialValue: name)
        _linkString = State(initialValue: linkString)
        _isSSLRequired = State(initialValue: isSSLRequired)
        _projectIds = State(initialValue: selectedProjectIds)
        _service = State(initialValue: service)
        self.candidates = candidates
        self.errors = errors
    }

    var body: some View {
        ScrollView {
            DatabaseSectionView(
                name: $name,
                projectIds: $projectIds,
                service: $service,
                expireDate: $expireDate,
                environment: $environment,
                memo: $memo,
                database: databaseBinding,
                availableProjects: previewProjects,
                serviceCandidates: candidates,
                validationErrors: errors,
                detectedServices: [:],
                onCreateProject: {}
            )
            .padding(16)
        }
    }

    private var databaseBinding: Binding<DatabaseFields> {
        Binding(
            get: {
                DatabaseFields(linkString: linkString, isSSLRequired: isSSLRequired)
            },
            set: {
                linkString = $0.linkString
                isSSLRequired = $0.isSSLRequired
            }
        )
    }
}

#endif
