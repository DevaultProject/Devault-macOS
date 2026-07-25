// Copyright © 2026 Devault. All rights reserved

import DVDesign
import DVDomain
import SwiftUI

/// `CreatableSecretType.oauth`의 `.serviceAccount` 서브타입 폼 섹션.
/// Figma상 Environment 필드 없음 — 도메인은 default `.dev` 유지 (UI 노출 X).
struct ServiceAccountSectionView: View {

    // MARK: - Common Fields (Environment 없음)

    @Binding var name: String
    @Binding var projectIds: [Project.ID]
    @Binding var service: String
    @Binding var expireDate: Date?
    @Binding var memo: String

    // MARK: - Type-Specific

    /// `ServiceAccountFields`: `.credentialJSON`(required) + `.authority`("Authority / Scope").
    @Binding var serviceAccount: ServiceAccountFields

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
                label: "Certification JSON",
                placeholder: #"e.g {"type": "service_account", ...}"#,
                text: $serviceAccount.credentialJSON,
                isRequired: true,
                sizeMode: .fullWidth,
                trailingHint: hintFor(.credentialJSON)
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

            /// 오른쪽 슬롯 비어있는 paired row — Environment 미노출로 ExpireDate 단독.
            /// Color.clear로 슬롯 유지해 wide/narrow 모두 자연스러운 전환.
            AdaptiveFieldRow {
                ExpireDateFieldView(expireDate: $expireDate)
            } right: {
                Color.clear
            }

            LabeledTextFieldView(
                label: "Authority / Scope",
                placeholder: "e.g organization-admin",
                text: $serviceAccount.authority,
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
            return .detected("Auto-detected: \(detected)")
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
    ServiceAccountSectionPreview()
        .padding(24)
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Filled · Dual (Wide)") {
    ServiceAccountSectionPreview(
        name: "GCP Service Account",
        credentialJSON: #"{"type": "service_account", "project_id": "my-proj"}"#,
        authority: "organization-admin",
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id)),
        candidates: ["GCP"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Filled · Single (Narrow)") {
    ServiceAccountSectionPreview(
        name: "GCP Service Account",
        credentialJSON: #"{"type": "service_account", ...}"#,
        authority: "organization-admin",
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id)),
        candidates: ["GCP"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .single)
    .previewWidth(.narrow)
}

#Preview("Validation errors · Dual") {
    ServiceAccountSectionPreview(
        errors: [.name: "Required", .credentialJSON: "Required"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

private struct ServiceAccountSectionPreview: View {

    @State var name: String
    @State var credentialJSON: String
    @State var authority: String
    @State var projectIds: [Project.ID]
    @State var service: String
    @State var expireDate: Date? = nil
    @State var memo: String = ""

    let candidates: [String]
    let errors: [SecretMetaFields.FieldID: String]

    init(
        name: String = "",
        credentialJSON: String = "",
        authority: String = "",
        selectedProjectIds: [Project.ID] = [],
        service: String = "",
        candidates: [String] = [],
        errors: [SecretMetaFields.FieldID: String] = [:]
    ) {
        _name = State(initialValue: name)
        _credentialJSON = State(initialValue: credentialJSON)
        _authority = State(initialValue: authority)
        _projectIds = State(initialValue: selectedProjectIds)
        _service = State(initialValue: service)
        self.candidates = candidates
        self.errors = errors
    }

    var body: some View {
        ScrollView {
            ServiceAccountSectionView(
                name: $name,
                projectIds: $projectIds,
                service: $service,
                expireDate: $expireDate,
                memo: $memo,
                serviceAccount: serviceAccountBinding,
                availableProjects: previewProjects,
                serviceCandidates: candidates,
                validationErrors: errors,
                detectedServices: [:],
                onCreateProject: {}
            )
            .padding(16)
        }
    }

    private var serviceAccountBinding: Binding<ServiceAccountFields> {
        Binding(
            get: {
                ServiceAccountFields(
                    credentialJSON: credentialJSON,
                    authority: authority
                )
            },
            set: {
                credentialJSON = $0.credentialJSON
                authority = $0.authority
            }
        )
    }
}

#endif
