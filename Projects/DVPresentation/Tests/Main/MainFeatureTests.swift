// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("MainFeature")
struct MainFeatureTests {

  // MARK: - Sidebar Delegate

  @Test("selectionChanged(.project)는 secretList를 해당 프로젝트로 갱신한다")
  func selectionChangedUpdatesSecretList() async {
    let item = ProjectItem(id: UUID(), name: "Backend")

    var initial = MainFeature.State()
    initial.sidebar.projectsState = .loaded([item])

    let store = TestStore(initialState: initial) {
      MainFeature()
    }

    await store.send(.sidebar(.didSelect(.project(id: item.id)))) {
      $0.sidebar.selection = .project(id: item.id)
    }
    await store.receive(.sidebar(.delegate(.selectionChanged(.project(id: item.id))))) {
      $0.secretList = SecretListFeature.State(
        collection: .project(id: item.id),
        projectName: "Backend"
      )
    }
    await store.receive(.sidebar(.setCreatingSecret(false)))
  }

  @Test("selectionChanged는 selectSecretType을 닫고 isCreatingSecret을 false로 만든다")
  func selectionChangedClosesSecretTypeSelection() async {
    var initial = MainFeature.State()
    initial.selectSecretType = .init()
    initial.sidebar.isCreatingSecret = true
    initial.sidebar.selection = .filter(.starred)

    let store = TestStore(initialState: initial) {
      MainFeature()
    }

    await store.send(.sidebar(.didSelect(.filter(.all)))) {
      $0.sidebar.selection = .filter(.all)
    }
    await store.receive(.sidebar(.delegate(.selectionChanged(.filter(.all))))) {
      $0.selectSecretType = nil
    }
    await store.receive(.sidebar(.setCreatingSecret(false))) {
      $0.sidebar.isCreatingSecret = false
    }
  }

  @Test("addButtonTapped은 selectSecretType을 열고 isCreatingSecret을 true로 만든다")
  func addButtonTappedOpensSecretTypeSelection() async {
    let store = TestStore(initialState: MainFeature.State()) {
      MainFeature()
    }

    await store.send(.sidebar(.didTapAddButton))
    await store.receive(.sidebar(.delegate(.addButtonTapped))) {
      $0.selectSecretType = .init()
    }
    await store.receive(.sidebar(.setCreatingSecret(true))) {
      $0.sidebar.isCreatingSecret = true
    }
  }

  @Test("addProjectTapped은 createProject sheet를 연다")
  func addProjectTappedOpensSheet() async {
    let store = TestStore(initialState: MainFeature.State()) {
      MainFeature()
    }

    await store.send(.sidebar(.didTapAddProject))
    await store.receive(.sidebar(.delegate(.addProjectTapped))) {
      $0.createProject = CreateProjectFeature.State()
    }
  }

  // MARK: - CreateProject Delegate

  @Test("projectCreated는 isCreatingSecret이 false일 때 selection을 새 프로젝트로 설정하고 refetch한다")
  func projectCreatedSelectsNewProject() async {
    let item = ProjectItem(id: UUID(), name: "Backend")

    var initial = MainFeature.State()
    initial.createProject = .init()
    initial.sidebar.isCreatingSecret = false

    let store = TestStore(initialState: initial) {
      MainFeature()
    } withDependencies: {
      $0.sidebarClient.fetchProjects = { [item] }
    }

    await store.send(.createProject(.presented(.delegate(.projectCreated(item))))) {
      $0.createProject = nil
      $0.sidebar.selection = .project(id: item.id)
      $0.secretList = SecretListFeature.State(
        collection: .project(id: item.id),
        projectName: "Backend"
      )
    }
    await store.receive(.sidebar(.task)) {
      $0.sidebar.projectsState = .loading
    }
    await store.receive(.sidebar(.projectsResponse(.success([item])))) {
      $0.sidebar.projectsState = .loaded([item])
    }
  }

  @Test("projectCreated는 isCreatingSecret이 true일 때 selection을 변경하지 않는다")
  func projectCreatedDoesNotSelectWhenCreatingSecret() async {
    let item = ProjectItem(id: UUID(), name: "Backend")

    var initial = MainFeature.State()
    initial.createProject = .init()
    initial.sidebar.isCreatingSecret = true

    let store = TestStore(initialState: initial) {
      MainFeature()
    } withDependencies: {
      $0.sidebarClient.fetchProjects = { [item] }
    }

    await store.send(.createProject(.presented(.delegate(.projectCreated(item))))) {
      $0.createProject = nil
      // selection 및 secretList 변경 없음
    }
    await store.receive(.sidebar(.task)) {
      $0.sidebar.projectsState = .loading
    }
    await store.receive(.sidebar(.projectsResponse(.success([item])))) {
      $0.sidebar.projectsState = .loaded([item])
    }
  }

  // MARK: - Rename Delegate

  @Test("projectRenamed는 현재 선택된 프로젝트의 이름이면 secretList 타이틀을 갱신한다")
  func projectRenamedUpdatesSecretListTitle() async {
    let item = ProjectItem(id: UUID(), name: "Backend")
    let renamed = ProjectItem(id: item.id, name: "Backend V2")

    var initial = MainFeature.State()
    initial.sidebar.projectsState = .loaded([item])
    initial.sidebar.selection = .project(id: item.id)
    initial.secretList = SecretListFeature.State(
      collection: .project(id: item.id),
      projectName: "Backend"
    )

    let store = TestStore(initialState: initial) {
      MainFeature()
    } withDependencies: {
      $0.sidebarClient.fetchProjects = { [renamed] }
    }

    await store.send(.sidebar(.renameResponse(.success(renamed))))
    // delegate payload의 이름을 직접 사용해 즉시 갱신
    await store.receive(.sidebar(.delegate(.projectRenamed(renamed)))) {
      $0.secretList = SecretListFeature.State(
        collection: .project(id: item.id),
        projectName: "Backend V2"
      )
    }
    // 이후 refetch로 목록도 동기화
    await store.receive(.sidebar(.task)) {
      $0.sidebar.projectsState = .loading
    }
    await store.receive(.sidebar(.projectsResponse(.success([renamed])))) {
      $0.sidebar.projectsState = .loaded([renamed])
    }
  }
}
