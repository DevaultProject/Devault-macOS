// Copyright © 2026 Devault. All rights reserved

import DVDomain
import SwiftUI

public struct SecretUseCaseDemoView: View {
    private let createSecretUseCase: any CreateSecretUseCase
    private let fetchSecretUseCase: any FetchSecretUseCase

    @State private var selectedSecret: Secret?
    @State private var revealedPayload: APIKeyPayload?
    @State private var secrets: [Secret] = []
    @State private var statusMessage = "Ready"
    @State private var isRunning = false

    public init(
        createSecretUseCase: any CreateSecretUseCase,
        fetchSecretUseCase: any FetchSecretUseCase
    ) {
        self.createSecretUseCase = createSecretUseCase
        self.fetchSecretUseCase = fetchSecretUseCase
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            controls
            status
            content
        }
        .padding(24)
        .frame(minWidth: 760, minHeight: 480)
        .task {
            await fetchAllSecrets()
        }
    }
}

private extension SecretUseCaseDemoView {
    var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Secret CRUD Demo")
                .font(.title2)
                .fontWeight(.semibold)
            Text("UseCase 기반 생성, 목록 조회, 상세 조회, payload reveal 확인")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    var controls: some View {
        HStack(spacing: 10) {
            Button {
                Task { await createDemoSecret() }
            } label: {
                Text(isRunning ? "Creating..." : "Demo Create")
            }
            .disabled(isRunning)
            .keyboardShortcut(.defaultAction)

            Button("Refresh") {
                Task { await fetchAllSecrets() }
            }
            .disabled(isRunning)
        }
    }

    var status: some View {
        Text(statusMessage)
            .font(.callout)
            .foregroundStyle(isRunning ? .secondary : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    var content: some View {
        HStack(alignment: .top, spacing: 20) {
            list
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
            Divider()
            detail
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    var list: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Secrets")
                    .font(.headline)
                Spacer()
                Text("\(secrets.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            List(secrets, selection: selectedSecretBinding) { secret in
                VStack(alignment: .leading, spacing: 5) {
                    Text(secret.name)
                        .font(.callout)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(secret.updatedAt.formatted(date: .numeric, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(secret.id)
            }
        }
    }

    var detail: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Detail")
                    .font(.headline)
                Spacer()
                Button("Reveal Payload") {
                    Task { await revealSelectedPayload() }
                }
                .disabled(isRunning || selectedSecret == nil)
            }

            if let selectedSecret {
                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
                    resultRow("ID", selectedSecret.id.uuidString)
                    resultRow("Name", selectedSecret.name)
                    resultRow("Type", selectedSecret.secretType.rawValue)
                    resultRow("Service", selectedSecret.service ?? "-")
                    resultRow("Environment", selectedSecret.environment ?? "-")
                    resultRow("Liked", selectedSecret.liked ? "true" : "false")
                    resultRow("Created", selectedSecret.createdAt.formatted(date: .numeric, time: .standard))
                    resultRow("Updated", selectedSecret.updatedAt.formatted(date: .numeric, time: .standard))
                    resultRow("Memo", selectedSecret.memo ?? "-")
                    resultRow("Encrypted bytes", "\(selectedSecret.payload.encryptedData.count)")
                    resultRow("Payload", revealedPayload?.value ?? "Hidden")
                }
                .font(.callout)
            } else {
                Text("Select a secret from the list.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    var selectedSecretBinding: Binding<UUID?> {
        Binding(
            get: { selectedSecret?.id },
            set: { id in
                selectedSecret = secrets.first { $0.id == id }
                revealedPayload = nil
            }
        )
    }

    func resultRow(_ title: String, _ value: String) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
    }

    func createDemoSecret() async {
        await run("Creating secret...") {
            let timestamp = Int(Date().timeIntervalSince1970)
            let draft = SecretDraft(
                name: "Demo Secret \(timestamp)",
                secretType: .apiKeyToken,
                subType: .apiKey,
                service: "github",
                environment: "development",
                memo: "Created from temporary Presentation UseCase demo",
                liked: true
            )
            let payload = APIKeyPayload(value: "demo-api-key-\(timestamp)")
            let metadata = APIKeyMetadata(scope: "repo")

            let created = try await createSecretUseCase.execute(
                draft: draft,
                payload: payload,
                metadata: metadata,
                projectIDs: []
            )
            secrets = try await fetchSecretUseCase.fetch(query: SecretQuery())
            selectedSecret = try await fetchSecretUseCase.fetch(id: created.id)
            revealedPayload = nil
            statusMessage = "Created demo secret"
        }
    }

    func revealSelectedPayload() async {
        guard let id = selectedSecret?.id else { return }

        await run("Revealing payload...") {
            revealedPayload = try await fetchSecretUseCase.revealPayload(id: id, as: APIKeyPayload.self)
            statusMessage = "Payload revealed"
        }
    }

    func fetchAllSecrets() async {
        await run("Fetching secrets...") {
            secrets = try await fetchSecretUseCase.fetch(query: SecretQuery())
            if let selectedID = selectedSecret?.id {
                selectedSecret = secrets.first { $0.id == selectedID }
            } else {
                selectedSecret = secrets.first
            }
            revealedPayload = nil
            statusMessage = "Fetched \(secrets.count) secret(s)"
        }
    }

    func run(_ message: String, operation: () async throws -> Void) async {
        isRunning = true
        statusMessage = message

        do {
            try await operation()
        } catch {
            statusMessage = "Failed: \(error)"
        }

        isRunning = false
    }
}
