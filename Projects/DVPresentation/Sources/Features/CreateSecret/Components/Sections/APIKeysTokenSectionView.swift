// Copyright © 2026 Devault. All rights reserved

import DVDesign
import DVDomain
import SwiftUI

/// `CreatableSecretType.apiKeyToken`의 3 서브타입(apiKey / accessToken / webhookSecret)이
/// 공유하는 폼 섹션 — 3 서브타입 모두 필드 구성 동일.
struct APIKeysTokenSectionView: View, CreateSecretSectionHintProviding {

    // MARK: - Common Fields

    @Binding var name: String
    @Binding var projectIds: [Project.ID]
    @Binding var service: String
    @Binding var expireDate: Date?
    @Binding var environment: SecretEnvironment
    @Binding var memo: String

    // MARK: - Type-Specific

    /// `APIKeyTokenFields`: `.value`(required) + `.authorityScope`("Authority / Scope").
    @Binding var apiKeyToken: APIKeyTokenFields

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
                placeholder: .module("e.g ghp_1234567890"),
                text: $apiKeyToken.value,
                isRequired: true,
                sizeMode: .fullWidth,
                trailingHint: valueHint
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
                label: .module("Authority / Scope"),
                placeholder: .module("e.g repo:read, user:email"),
                text: $apiKeyToken.authorityScope,
                sizeMode: .fullWidth
            )
        }
    }

    /// Value 필드 우측 hint: warning(validation) > detected(감지) 순.
    private var valueHint: DVLabeledField<DVTextField>.TrailingHint? {
        if let warning = validationErrors[.value] {
            return .warning(warning)
        }
        if let detected = detectedServices[.value] {
            return .detected(.module("Auto-detected: \(detected)"))
        }
        return nil
    }
}

// MARK: - Preview

#if DEBUG

private let previewProjects: [Project] = [
    Project(id: UUID(), name: "DrinkiG",     createdAt: Date(), updatedAt: Date()),
    Project(id: UUID(), name: "Longlonglong Project Name", createdAt: Date(), updatedAt: Date()),
    Project(id: UUID(), name: "CheerLot",    createdAt: Date(), updatedAt: Date()),
    Project(id: UUID(), name: "SipStream",   createdAt: Date(), updatedAt: Date()),
]

#Preview("Empty · Dual (Wide)") {
    APIKeysTokenSectionPreview()
        .padding(24)
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Filled + hint · Dual (Wide)") {
    APIKeysTokenSectionPreview(
        name: "GitHub Access Token",
        value: "ghp_1234567890",
        selectedProjectIds: Array(previewProjects.prefix(2).map(\.id)),
        service: "",
        candidates: ["GitHub", "NameNameName"],
        detectedValue: "GitHub"
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Filled · Single (Narrow)") {
    APIKeysTokenSectionPreview(
        name: "GitHub Access Token",
        value: "ghp_1234567890",
        selectedProjectIds: Array(previewProjects.prefix(2).map(\.id)),
        service: "",
        candidates: ["GitHub", "NameNameName"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .single)
    .previewWidth(.narrow)
}

#Preview("Validation errors · Dual") {
    APIKeysTokenSectionPreview(
        errors: [.name: "Required", .value: "Required"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

private struct APIKeysTokenSectionPreview: View {

    @State var name: String
    @State var value: String
    @State var authorityScope: String = ""
    @State var projectIds: [Project.ID]
    @State var service: String
    @State var expireDate: Date? = nil
    @State var environment: SecretEnvironment = .staging
    @State var memo: String = ""

    let candidates: [String]
    let errors: [SecretMetaFields.FieldID: String]
    let detectedValue: String?

    init(
        name: String = "",
        value: String = "",
        selectedProjectIds: [Project.ID] = [],
        service: String = "",
        candidates: [String] = [],
        errors: [SecretMetaFields.FieldID: String] = [:],
        detectedValue: String? = nil
    ) {
        _name = State(initialValue: name)
        _value = State(initialValue: value)
        _projectIds = State(initialValue: selectedProjectIds)
        _service = State(initialValue: service)
        self.candidates = candidates
        self.errors = errors
        self.detectedValue = detectedValue
    }

    var body: some View {
        ScrollView {
            APIKeysTokenSectionView(
                name: $name,
                projectIds: $projectIds,
                service: $service,
                expireDate: $expireDate,
                environment: $environment,
                memo: $memo,
                apiKeyToken: apiKeyTokenBinding,
                availableProjects: previewProjects,
                serviceCandidates: candidates,
                validationErrors: errors,
                detectedServices: detectedValue.map { [.value: $0] } ?? [:],
                onCreateProject: {}
            )
            .padding(16)
        }
    }

    private var apiKeyTokenBinding: Binding<APIKeyTokenFields> {
        Binding(
            get: { APIKeyTokenFields(value: value, authorityScope: authorityScope) },
            set: {
                value = $0.value
                authorityScope = $0.authorityScope
            }
        )
    }
}

#endif
