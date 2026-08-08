// Copyright © 2026 Devault. All rights reserved

import DVDesign
import DVDomain
import SwiftUI

/// `CreatableSecretType.etc`의 `.custom` 서브타입 폼 섹션 — 최소 구성 (5 rows).
struct CustomSectionView: View, CreateSecretSectionHintProviding {

    // MARK: - Common Fields

    @Binding var name: String
    @Binding var projectIds: [Project.ID]
    @Binding var service: String
    @Binding var expireDate: Date?
    @Binding var environment: SecretEnvironment
    @Binding var memo: String

    // MARK: - Type-Specific

    /// `CustomFields`: `.value`(required) 단일 필드.
    @Binding var custom: CustomFields

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
                label: .module("Value"),
                placeholder: .module("e.g custom-secret-value"),
                text: $custom.value,
                isRequired: true,
                sizeMode: .fullWidth,
                trailingHint: hintFor(.value)
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
    CustomSectionPreview()
        .padding(24)
        .formLayout(.dual)
        .previewWidth(.wide)
}

#Preview("Filled · Dual (Wide)") {
    CustomSectionPreview(
        name: "Legacy Custom Secret",
        value: "abc123-legacy-value",
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id)),
        candidates: ["Legacy"]
    )
    .padding(24)
    .formLayout(.dual)
    .previewWidth(.wide)
}

#Preview("Filled · Single (Narrow)") {
    CustomSectionPreview(
        name: "Legacy Custom Secret",
        value: "abc123-legacy-value",
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id))
    )
    .padding(24)
    .formLayout(.single)
    .previewWidth(.narrow)
}

#Preview("Validation errors · Dual") {
    CustomSectionPreview(
        errors: [.name: "Required", .value: "Required"]
    )
    .padding(24)
    .formLayout(.dual)
    .previewWidth(.wide)
}

private struct CustomSectionPreview: View {

    @State var name: String
    @State var value: String
    @State var projectIds: [Project.ID]
    @State var service: String
    @State var expireDate: Date? = nil
    @State var environment: SecretEnvironment = .staging
    @State var memo: String = ""

    let candidates: [String]
    let errors: [SecretMetaFields.FieldID: String]

    init(
        name: String = "",
        value: String = "",
        selectedProjectIds: [Project.ID] = [],
        service: String = "",
        candidates: [String] = [],
        errors: [SecretMetaFields.FieldID: String] = [:]
    ) {
        _name = State(initialValue: name)
        _value = State(initialValue: value)
        _projectIds = State(initialValue: selectedProjectIds)
        _service = State(initialValue: service)
        self.candidates = candidates
        self.errors = errors
    }

    var body: some View {
        ScrollView {
            CustomSectionView(
                name: $name,
                projectIds: $projectIds,
                service: $service,
                expireDate: $expireDate,
                environment: $environment,
                memo: $memo,
                custom: customBinding,
                availableProjects: previewProjects,
                serviceCandidates: candidates,
                validationErrors: errors,
                detectedServices: [:],
                onCreateProject: {}
            )
            .padding(16)
        }
    }

    private var customBinding: Binding<CustomFields> {
        Binding(
            get: { CustomFields(value: value) },
            set: { value = $0.value }
        )
    }
}

#endif
