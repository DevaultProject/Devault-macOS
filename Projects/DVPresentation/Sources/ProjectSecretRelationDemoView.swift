// Copyright © 2026 Devault. All rights reserved

import DVDomain
import SwiftUI

public struct ProjectSecretRelationDemoView: View {
    private let createProjectUseCase: any CreateProjectUseCase
    private let fetchProjectUseCase: any FetchProjectUseCase
    private let createSecretUseCase: any CreateSecretUseCase
    private let fetchSecretUseCase: any FetchSecretUseCase
    private let secretProjectRelationUseCase: any SecretProjectRelationUseCase

    @State private var projects: [Project] = []
    @State private var projectSecrets: [Secret] = []
    @State private var secretProjects: [Project] = []
    @State private var selectedProject: Project?
    @State private var selectedSecret: Secret?
    @State private var statusMessage = "Ready"
    @State private var isRunning = false

    public init(
        createProjectUseCase: any CreateProjectUseCase,
        fetchProjectUseCase: any FetchProjectUseCase,
        createSecretUseCase: any CreateSecretUseCase,
        fetchSecretUseCase: any FetchSecretUseCase,
        secretProjectRelationUseCase: any SecretProjectRelationUseCase
    ) {
        self.createProjectUseCase = createProjectUseCase
        self.fetchProjectUseCase = fetchProjectUseCase
        self.createSecretUseCase = createSecretUseCase
        self.fetchSecretUseCase = fetchSecretUseCase
        self.secretProjectRelationUseCase = secretProjectRelationUseCase
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            controls
            status
            content
        }
        .padding(24)
        .frame(minWidth: 900, minHeight: 560)
        .task {
            await refreshProjects()
        }
    }
}

private extension ProjectSecretRelationDemoView {
    var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Project ↔ Secret Relation Demo")
                .font(.title2)
                .fontWeight(.semibold)
            Text("create 시 link, fetchProjects, fetchSecrets(by project), SecretProjectRelationUseCase link/unlink 확인")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    var controls: some View {
        HStack(spacing: 10) {
            Button("Create Project + Secret (Linked)") {
                Task { await createLinkedDemoData() }
            }
            .disabled(isRunning)
            .keyboardShortcut(.defaultAction)

            Button("Create Secret Only") {
                Task { await createUnlinkedSecret() }
            }
            .disabled(isRunning)

            Button("Link Selected") {
                Task { await linkSelected() }
            }
            .disabled(isRunning || selectedProject == nil || selectedSecret == nil)

            Button("Unlink Selected") {
                Task { await unlinkSelected() }
            }
            .disabled(isRunning || selectedProject == nil || selectedSecret == nil)

            Button("Refresh") {
                Task { await refreshAll() }
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
            projectList
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 300)
            Divider()
            secretList
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 360)
            Divider()
            relationDetail
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    var projectList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Projects")
                    .font(.headline)
                Spacer()
                Text("\(projects.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            List(projects, selection: selectedProjectBinding) { project in
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.callout)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(project.updatedAt.formatted(date: .numeric, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(project.id)
            }
        }
    }

    var secretList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(selectedProject != nil ? "Secrets in Project" : "All Secrets")
                    .font(.headline)
                Spacer()
                Text("\(projectSecrets.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            List(projectSecrets, selection: selectedSecretBinding) { secret in
                VStack(alignment: .leading, spacing: 4) {
                    Text(secret.name)
                        .font(.callout)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(secret.secretType.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(secret.id)
            }
        }
    }

    var relationDetail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Relation Detail")
                .font(.headline)

            Group {
                resultRow("Selected Project", selectedProject?.name ?? "-")
                resultRow("Selected Secret", selectedSecret?.name ?? "-")
            }

            Divider()

            Text("Projects linked to selected Secret")
                .font(.subheadline)
                .fontWeight(.semibold)

            if secretProjects.isEmpty {
                Text("No linked projects.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(secretProjects) { project in
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                        Text(project.name)
                            .font(.callout)
                    }
                }
            }
        }
    }

    var selectedProjectBinding: Binding<UUID?> {
        Binding(
            get: { selectedProject?.id },
            set: { id in
                selectedProject = projects.first { $0.id == id }
                selectedSecret = nil
                secretProjects = []
                Task { await refreshProjectSecrets() }
            }
        )
    }

    var selectedSecretBinding: Binding<UUID?> {
        Binding(
            get: { selectedSecret?.id },
            set: { id in
                selectedSecret = projectSecrets.first { $0.id == id }
                Task { await refreshSecretProjects() }
            }
        )
    }

    func resultRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .font(.callout)
    }

    // MARK: - Actions

    func createLinkedDemoData() async {
        await run("Creating project + secret with link...") {
            let timestamp = Int(Date().timeIntervalSince1970)
            let project = try await createProjectUseCase.execute(name: "Demo Project \(timestamp)")
            let draft = SecretDraft(
                name: "Linked Secret \(timestamp)",
                secretType: .apiKeyToken,
                subType: .accessToken,
                service: "github",
                environment: "production",
                memo: "Created with projectIDs at create time"
            )
            let payload = APIKeyPayload(value: "demo-token-\(timestamp)")
            // CreateSecretUseCase가 create + link를 한 번에 처리
            let secret = try await createSecretUseCase.execute(
                draft: draft,
                payload: payload,
                projectIDs: [project.id]
            )
            await refreshAll()
            selectedProject = projects.first { $0.id == project.id }
            await refreshProjectSecrets()
            selectedSecret = projectSecrets.first { $0.id == secret.id }
            await refreshSecretProjects()
            statusMessage = "Created project + secret and linked via CreateSecretUseCase"
        }
    }

    func createUnlinkedSecret() async {
        await run("Creating secret without link...") {
            let timestamp = Int(Date().timeIntervalSince1970)
            let draft = SecretDraft(
                name: "Unlinked Secret \(timestamp)",
                secretType: .apiKeyToken,
                subType: .apiKey,
                service: "standalone",
                environment: "development"
            )
            let payload = APIKeyPayload(value: "demo-key-\(timestamp)")
            // projectIDs: [] 로 link 없이 생성
            _ = try await createSecretUseCase.execute(
                draft: draft,
                payload: payload,
                projectIDs: []
            )
            await refreshProjectSecrets()
            statusMessage = "Created secret without project link"
        }
    }

    func linkSelected() async {
        guard let selectedProject, let selectedSecret else { return }
        await run("Linking via SecretProjectRelationUseCase...") {
            // SecretProjectRelationUseCase — 단독 link 조작
            try await secretProjectRelationUseCase.link(
                secretID: selectedSecret.id,
                projectID: selectedProject.id
            )
            await refreshProjectSecrets()
            await refreshSecretProjects()
            statusMessage = "Linked \(selectedSecret.name) → \(selectedProject.name)"
        }
    }

    func unlinkSelected() async {
        guard let selectedProject, let selectedSecret else { return }
        await run("Unlinking via SecretProjectRelationUseCase...") {
            // SecretProjectRelationUseCase — 단독 unlink 조작
            try await secretProjectRelationUseCase.unlink(
                secretID: selectedSecret.id,
                projectID: selectedProject.id
            )
            await refreshProjectSecrets()
            await refreshSecretProjects()
            statusMessage = "Unlinked \(selectedSecret.name) → \(selectedProject.name)"
        }
    }

    // MARK: - Fetch helpers

    func refreshAll() async {
        await run("Refreshing...") {
            try await refreshProjectsContent()
            await refreshProjectSecrets()
            await refreshSecretProjects()
            statusMessage = "Refreshed"
        }
    }

    func refreshProjects() async {
        await run("Fetching projects...") {
            try await refreshProjectsContent()
            statusMessage = "Fetched \(projects.count) project(s)"
        }
    }

    func refreshProjectsContent() async throws {
        projects = try await fetchProjectUseCase.fetchAll()
        if let selectedID = selectedProject?.id {
            selectedProject = projects.first { $0.id == selectedID }
        } else {
            selectedProject = projects.first
        }
    }

    func refreshProjectSecrets() async {
        if let selectedProject {
            // FetchSecretUseCase.fetch(query:) — SecretQuery.collection.project 로 Project 기준 조회
            await run("Fetching secrets for project...") {
                projectSecrets = try await fetchSecretUseCase.fetch(
                    query: SecretQuery(collection: .project(id: selectedProject.id))
                )
                if let selectedID = selectedSecret?.id {
                    selectedSecret = projectSecrets.first { $0.id == selectedID }
                }
                statusMessage = "Fetched \(projectSecrets.count) secret(s) for project"
            }
        } else {
            // Project 미선택 시 전체 Secret 표시
            await run("Fetching all secrets...") {
                projectSecrets = try await fetchSecretUseCase.fetch(query: SecretQuery())
                statusMessage = "Fetched \(projectSecrets.count) secret(s)"
            }
        }
    }

    func refreshSecretProjects() async {
        guard let selectedSecret else {
            secretProjects = []
            return
        }
        // FetchSecretUseCase.fetchProjects — Secret 기준 연결된 Project 조회
        await run("Fetching projects for secret...") {
            secretProjects = try await fetchSecretUseCase.fetchProjects(secretID: selectedSecret.id)
            statusMessage = "Fetched \(secretProjects.count) project(s) for secret"
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
