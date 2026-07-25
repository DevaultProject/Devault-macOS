// Copyright © 2026 Devault. All rights reserved

import DVDesign
import DVDomain
import SwiftUI

/// `CreatableSecretType.sshAndCredentials`의 `.sshKey` 서브타입 폼 섹션.
/// Figma상 Services / Expire Date 필드 없음 — common 바인딩에서도 제외.
struct SSHKeySectionView: View, CreateSecretSectionHintProviding {

    // MARK: - Common Fields (Services / ExpireDate 없음)

    @Binding var name: String
    @Binding var projectIds: [Project.ID]
    @Binding var environment: SecretEnvironment
    @Binding var memo: String

    // MARK: - Type-Specific

    /// `SSHKeyFields`: `.privateKey`(required) + `.publicKey` + `.passphrase` + `.host` + `.username`.
    @Binding var sshKey: SSHKeyFields

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
                label: .module("Private Key"),
                placeholder: .module("e.g -----BEGIN OPENSSH PRIVATE KEY-----"),
                text: $sshKey.privateKey,
                isRequired: true,
                sizeMode: .fullWidth,
                trailingHint: hintFor(.privateKey)
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
                label: .module("Public Key"),
                placeholder: .module("e.g ssh-rsa AAAA..."),
                text: $sshKey.publicKey,
                sizeMode: .fullWidth
            )

            LabeledTextFieldView(
                label: .module("PassPhrase"),
                placeholder: .module("optional"),
                text: $sshKey.passphrase,
                sizeMode: .fullWidth
            )

            AdaptiveFieldRow {
                LabeledTextFieldView(
                    label: .module("Host"),
                    placeholder: .module("e.g example.com"),
                    text: $sshKey.host,
                    sizeMode: .paired
                )
            } right: {
                LabeledTextFieldView(
                    label: .module("Username"),
                    placeholder: .module("e.g root"),
                    text: $sshKey.username,
                    sizeMode: .paired
                )
            }

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
    SSHKeySectionPreview()
        .padding(24)
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Filled · Dual (Wide)") {
    SSHKeySectionPreview(
        name: "Bastion SSH Key",
        privateKey: "-----BEGIN OPENSSH PRIVATE KEY-----\n...",
        publicKey: "ssh-rsa AAAA...",
        passphrase: "secret-phrase",
        host: "bastion.example.com",
        username: "ubuntu",
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id))
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Filled · Single (Narrow)") {
    SSHKeySectionPreview(
        name: "Bastion SSH Key",
        privateKey: "-----BEGIN OPENSSH PRIVATE KEY-----",
        publicKey: "ssh-rsa AAAA...",
        host: "bastion.example.com",
        username: "ubuntu",
        selectedProjectIds: Array(previewProjects.prefix(1).map(\.id))
    )
    .padding(24)
    .environment(\.formLayoutMode, .single)
    .previewWidth(.narrow)
}

#Preview("Validation errors · Dual") {
    SSHKeySectionPreview(
        errors: [.name: "Required", .privateKey: "Required"]
    )
    .padding(24)
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

private struct SSHKeySectionPreview: View {

    @State var name: String
    @State var privateKey: String
    @State var publicKey: String
    @State var passphrase: String
    @State var host: String
    @State var username: String
    @State var projectIds: [Project.ID]
    @State var environment: SecretEnvironment = .staging
    @State var memo: String = ""

    let errors: [SecretMetaFields.FieldID: String]

    init(
        name: String = "",
        privateKey: String = "",
        publicKey: String = "",
        passphrase: String = "",
        host: String = "",
        username: String = "",
        selectedProjectIds: [Project.ID] = [],
        errors: [SecretMetaFields.FieldID: String] = [:]
    ) {
        _name = State(initialValue: name)
        _privateKey = State(initialValue: privateKey)
        _publicKey = State(initialValue: publicKey)
        _passphrase = State(initialValue: passphrase)
        _host = State(initialValue: host)
        _username = State(initialValue: username)
        _projectIds = State(initialValue: selectedProjectIds)
        self.errors = errors
    }

    var body: some View {
        ScrollView {
            SSHKeySectionView(
                name: $name,
                projectIds: $projectIds,
                environment: $environment,
                memo: $memo,
                sshKey: sshKeyBinding,
                availableProjects: previewProjects,
                validationErrors: errors,
                detectedServices: [:],
                onCreateProject: {}
            )
            .padding(16)
        }
    }

    private var sshKeyBinding: Binding<SSHKeyFields> {
        Binding(
            get: {
                SSHKeyFields(
                    privateKey: privateKey,
                    passphrase: passphrase,
                    publicKey: publicKey,
                    host: host,
                    username: username
                )
            },
            set: {
                privateKey = $0.privateKey
                passphrase = $0.passphrase
                publicKey = $0.publicKey
                host = $0.host
                username = $0.username
            }
        )
    }
}

#endif
