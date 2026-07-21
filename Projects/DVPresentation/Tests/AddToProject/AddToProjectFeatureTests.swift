// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("AddToProjectFeature")
struct AddToProjectFeatureTests {

    @Test("task는 조회에 성공하면 projects를 채운다")
    func taskSuccess() async {
        let project = makeProject(name: "CheerLot")
        let store = TestStore(initialState: AddToProjectFeature.State(secretID: UUID())) {
            AddToProjectFeature()
        } withDependencies: {
            $0.secretClient.fetchProjects = { [project] }
        }

        await store.send(.task) {
            $0.projectsState = .loading
        }
        await store.receive(.projectsResponse(.success([project]))) {
            $0.projectsState = .loaded([project])
        }
    }

    @Test("초기 State는 idle이며, 조회 후 결과가 0개인 loaded([])와 구분된다")
    func initialStateIsIdleNotLoaded() {
        let state = AddToProjectFeature.State(secretID: UUID())

        #expect(state.projectsState == .idle)
        #expect(state.projectsState != .loaded([]))
    }

    @Test("didSelectProject는 선택만 반영하고 아직 연결하지 않는다")
    func selectProjectOnlyUpdatesState() async {
        let project = makeProject(name: "CheerLot")
        let store = TestStore(initialState: AddToProjectFeature.State(secretID: UUID())) {
            AddToProjectFeature()
        }

        await store.send(.didSelectProject(id: project.id)) {
            $0.selectedProjectID = project.id
        }
    }

    @Test("didTapDone은 선택된 프로젝트가 없으면 아무 일도 안 한다")
    func doneIgnoresWhenNothingSelected() async {
        let store = TestStore(initialState: AddToProjectFeature.State(secretID: UUID())) {
            AddToProjectFeature()
        }

        await store.send(.didTapDone)
    }

    @Test("didTapDone은 선택된 프로젝트를 연결하고 성공하면 delegate로 알린 뒤 dismiss한다")
    func doneLinksSelectedProjectAndDismisses() async {
        let secretID = UUID()
        let project = makeProject(name: "CheerLot")
        var didDismiss = false
        var initialState = AddToProjectFeature.State(secretID: secretID)
        initialState.selectedProjectID = project.id
        let store = TestStore(initialState: initialState) {
            AddToProjectFeature()
        } withDependencies: {
            $0.secretClient.linkProject = { _, _ in }
            $0.dismiss = DismissEffect { didDismiss = true }
        }

        await store.send(.didTapDone)
        await store.receive(.linkResponse(.success(secretID)))
        await store.receive(.delegate(.projectLinked))

        #expect(didDismiss)
    }

    @Test("didTapCreateNewProject는 CreateProject destination을 연다")
    func createNewProjectPresentsDestination() async {
        let store = TestStore(initialState: AddToProjectFeature.State(secretID: UUID())) {
            AddToProjectFeature()
        }

        await store.send(.didTapCreateNewProject) {
            $0.destination = .createProject(CreateProjectFeature.State())
        }
    }

    @Test("CreateProject에서 프로젝트가 만들어지면 목록에 추가하고 선택 상태로 만든다 (연결/dismiss는 안 함)")
    func createdProjectIsAddedAndSelected() async {
        let secretID = UUID()
        let newProject = makeProject(name: "New Project")
        var initialState = AddToProjectFeature.State(secretID: secretID)
        initialState.destination = .createProject(CreateProjectFeature.State())
        let store = TestStore(initialState: initialState) {
            AddToProjectFeature()
        }

        await store.send(.destination(.presented(.createProject(.delegate(.projectCreated(newProject)))))) {
            $0.projectsState = .loaded([newProject])
            $0.selectedProjectID = newProject.id
        }
    }

    @Test("didTapCancel은 dismiss한다")
    func cancelDismisses() async {
        var didDismiss = false
        let store = TestStore(initialState: AddToProjectFeature.State(secretID: UUID())) {
            AddToProjectFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { didDismiss = true }
        }

        await store.send(.didTapCancel)

        #expect(didDismiss)
    }

    // MARK: - Helpers

    private func makeProject(name: String) -> Project {
        Project(id: UUID(), name: name, createdAt: .now, updatedAt: .now)
    }
}
