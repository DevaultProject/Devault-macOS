// Copyright © 2026 Devault. All rights reserved

import DVDesign
import DVDomain
import SwiftUI

/// `CreatableSecretType.sshAndCredentials`의 `.sslTlsCertificate` 서브타입 폼 섹션.
/// Figma상 Services / Expire Date 필드 없음 — common 바인딩에서도 제외.
struct SSLTLSCertSectionView: View, CreateSecretSectionHintProviding {

    // MARK: - Common Fields (Services / ExpireDate 없음)

    @Binding var name: String
    @Binding var projectIds: [Project.ID]
    @Binding var environment: SecretEnvironment
    @Binding var memo: String

    // MARK: - Type-Specific

    /// `SSLCertFields`: `.certificate`(required) + `.sslPrivateKey`(required) + `.certificateChain` + `.renewCommand`.
    @Binding var sslCert: SSLCertFields

    // MARK: - Context

    let availableProjects: [Project]
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
                label: .module("Certificate"),
                placeholder: .module("e.g -----BEGIN CERTIFICATE-----"),
                text: $sslCert.certificate,
                isRequired: true,
                sizeMode: .fullWidth,
                trailingHint: hintFor(.certificate)
            )

            LabeledTextFieldView(
                label: .module("Private Key"),
                placeholder: .module("e.g -----BEGIN PRIVATE KEY-----"),
                text: $sslCert.sslPrivateKey,
                isRequired: true,
                sizeMode: .fullWidth,
                trailingHint: hintFor(.sslPrivateKey)
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

            LabeledTextFieldView(
                label: .module("Certificate Chain"),
                placeholder: .module("optional"),
                text: $sslCert.certificateChain,
                sizeMode: .fullWidth
            )

            LabeledTextFieldView(
                label: .module("Renew Command"),
                placeholder: .module("e.g certbot renew"),
                text: $sslCert.renewCommand,
                sizeMode: .fullWidth
            )

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
]

#Preview("Empty · Dual (Wide)") {
    SSLTLSCertSectionPreview()
        .padding(24)
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Filled · Dual (Wide)") {
    SSLTLSCertSectionPreview(
        name: "example.com TLS",
        certificate: "-----BEGIN CERTIFICATE-----\n...",
        privateKey: "-----BEGIN PRIVATE KEY-----\n...",
        certificateChain: "-----BEGIN CERTIFICATE-----\n...",
        renewCommand: "certbot renew --cert-name example.com",
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id))
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Filled · Single (Narrow)") {
    SSLTLSCertSectionPreview(
        name: "example.com TLS",
        certificate: "-----BEGIN CERTIFICATE-----",
        privateKey: "-----BEGIN PRIVATE KEY-----",
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id))
    )
    .padding(24)
    .environment(\.formLayoutMode, .single)
    .previewWidth(.narrow)
}

#Preview("Validation errors · Dual") {
    SSLTLSCertSectionPreview(
        errors: [.name: "Required", .certificate: "Required", .sslPrivateKey: "Required"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

private struct SSLTLSCertSectionPreview: View {

    @State var name: String
    @State var certificate: String
    @State var privateKey: String
    @State var certificateChain: String
    @State var renewCommand: String
    @State var projectIds: [Project.ID]
    @State var environment: SecretEnvironment = .staging
    @State var memo: String = ""

    let errors: [SecretMetaFields.FieldID: String]

    init(
        name: String = "",
        certificate: String = "",
        privateKey: String = "",
        certificateChain: String = "",
        renewCommand: String = "",
        selectedProjectIds: [Project.ID] = [],
        errors: [SecretMetaFields.FieldID: String] = [:]
    ) {
        _name = State(initialValue: name)
        _certificate = State(initialValue: certificate)
        _privateKey = State(initialValue: privateKey)
        _certificateChain = State(initialValue: certificateChain)
        _renewCommand = State(initialValue: renewCommand)
        _projectIds = State(initialValue: selectedProjectIds)
        self.errors = errors
    }

    var body: some View {
        ScrollView {
            SSLTLSCertSectionView(
                name: $name,
                projectIds: $projectIds,
                environment: $environment,
                memo: $memo,
                sslCert: sslCertBinding,
                availableProjects: previewProjects,
                validationErrors: errors,
                detectedServices: [:],
                onCreateProject: {}
            )
            .padding(16)
        }
    }

    private var sslCertBinding: Binding<SSLCertFields> {
        Binding(
            get: {
                SSLCertFields(
                    certificate: certificate,
                    sslPrivateKey: privateKey,
                    certificateChain: certificateChain,
                    renewCommand: renewCommand
                )
            },
            set: {
                certificate = $0.certificate
                privateKey = $0.sslPrivateKey
                certificateChain = $0.certificateChain
                renewCommand = $0.renewCommand
            }
        )
    }
}

#endif
