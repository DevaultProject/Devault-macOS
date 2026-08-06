// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("SidebarFeature")
struct SidebarFeatureTests {

  // MARK: - Fetch

  @Test("task는 프로젝트 목록을 fetch해 이름 순으로 정렬한다")
  func taskFetchesSortedProjects() async {
    let projects = [
      ProjectItem(id: UUID(), name: "Mobile"),
      ProjectItem(id: UUID(), name: "Backend"),
    ]
    let store = TestStore(initialState: SidebarFeature.State()) {
      SidebarFeature()
    } withDependencies: {
      $0.sidebarClient.fetchProjects = { projects }
    }

    await store.send(.task) {
      $0.projectsState = .loading
    }
    await store.receive(.projectsResponse(.success(projects))) {
      $0.projectsState = .loaded(IdentifiedArray(uniqueElements: [
        ProjectItem(id: projects[1].id, name: "Backend"),
        ProjectItem(id: projects[0].id, name: "Mobile"),
      ]))
    }
  }

  @Test("task fetch 실패 시 projectsState가 .failed로 전환된다")
  func taskFetchFailureSetsFailedState() async {
    let store = TestStore(initialState: SidebarFeature.State()) {
      SidebarFeature()
    } withDependencies: {
      $0.sidebarClient.fetchProjects = { throw SidebarError.fetchFailed }
    }

    await store.send(.task) {
      $0.projectsState = .loading
    }
    await store.receive(.projectsResponse(.failure(.fetchFailed))) {
      $0.projectsState = .failed(.fetchFailed)
    }
  }

  // MARK: - Selection

  @Test("didSelect는 selection을 바꾸고 delegate를 발송한다")
  func didSelectChangesSelectionAndSendsDelegate() async {
    let id = UUID()
    let store = TestStore(
      initialState: SidebarFeature.State()
    ) {
      SidebarFeature()
    }

    await store.send(.didSelect(.project(id: id))) {
      $0.selection = .project(id: id)
    }
    await store.receive(.delegate(.selectionChanged(.project(id: id))))
  }

  // MARK: - Rename

  @Test("didTapRename은 renameText를 프로젝트 이름으로 세팅한다")
  func didTapRenameSetRenameText() async {
    let item = ProjectItem(id: UUID(), name: "Backend")
    var state = SidebarFeature.State()
    state.projectsState = .loaded([item])

    let store = TestStore(initialState: state) {
      SidebarFeature()
    }

    await store.send(.didTapRename(id: item.id)) {
      $0.renamingProjectID = item.id
      $0.renameText = "Backend"
    }
  }

  @Test("didConfirmRename 성공 시 delegate를 발송하고 refetch한다")
  func didConfirmRenameSuccessDelegate() async {
    let item = ProjectItem(id: UUID(), name: "Backend")
    let renamed = ProjectItem(id: item.id, name: "Backend V2")

    var state = SidebarFeature.State()
    state.projectsState = .loaded([item])
    state.renamingProjectID = item.id
    state.renameText = "Backend V2"

    let store = TestStore(initialState: state) {
      SidebarFeature()
    } withDependencies: {
      $0.sidebarClient.renameProject = { _, _ in renamed }
      $0.sidebarClient.fetchProjects = { [renamed] }
    }

    await store.send(.didConfirmRename) {
      $0.renamingProjectID = nil
      $0.renameText = ""
    }
    await store.receive(.renameResponse(.success(renamed)))
    await store.receive(.delegate(.projectRenamed(renamed)))
    await store.receive(.task) {
      $0.projectsState = .loading
    }
    await store.receive(.projectsResponse(.success([renamed]))) {
      $0.projectsState = .loaded([renamed])
    }
  }

  @Test("didConfirmRename에서 nameTaken 오류 시 alert가 표시된다")
  func didConfirmRenameNameTakenShowsAlert() async {
    let item = ProjectItem(id: UUID(), name: "Backend")
    var state = SidebarFeature.State()
    state.projectsState = .loaded([item])
    state.renamingProjectID = item.id
    state.renameText = "Mobile"

    let store = TestStore(initialState: state) {
      SidebarFeature()
    } withDependencies: {
      $0.sidebarClient.renameProject = { _, _ in throw SidebarError.nameTaken }
    }

    await store.send(.didConfirmRename) {
      $0.renamingProjectID = nil
      $0.renameText = ""
    }
    await store.receive(.renameResponse(.failure(.nameTaken))) {
      $0.alert = AlertState {
        TextState("이미 사용 중인 이름이에요")
      } actions: {
        ButtonState(role: .cancel) { TextState("확인") }
      } message: {
        TextState("다른 프로젝트 이름을 입력해주세요.")
      }
    }
  }

  @Test("didCancelRename은 rename 상태를 초기화한다")
  func didCancelRenameResetsState() async {
    var state = SidebarFeature.State()
    state.renamingProjectID = UUID()
    state.renameText = "Some Name"

    let store = TestStore(initialState: state) {
      SidebarFeature()
    }

    await store.send(.didCancelRename) {
      $0.renamingProjectID = nil
      $0.renameText = ""
    }
  }

  // MARK: - Delete

  @Test("didTapDelete는 alert를 표시한다")
  func didTapDeleteShowsAlert() async {
    let item = ProjectItem(id: UUID(), name: "Backend")
    var state = SidebarFeature.State()
    state.projectsState = .loaded([item])

    let store = TestStore(initialState: state) {
      SidebarFeature()
    }

    await store.send(.didTapDelete(id: item.id)) {
      $0.deletingProjectID = item.id
      $0.alert = AlertState {
        TextState("'\(item.name)' 프로젝트를 삭제할까요?")
      } actions: {
        ButtonState(role: .destructive, action: .confirmDelete) { TextState("삭제") }
        ButtonState(role: .cancel) { TextState("취소") }
      } message: {
        TextState("프로젝트에 속한 Secret과의 연결이 해제됩니다. Secret 자체는 삭제되지 않습니다.")
      }
    }
  }

  @Test("삭제 확인 후 선택 중이던 프로젝트면 selection이 .all로 초기화되고 refetch한다")
  func deleteResetsSelectionAndRefetches() async {
    let item = ProjectItem(id: UUID(), name: "Backend")

    var state = SidebarFeature.State()
    state.projectsState = .loaded([item])
    state.selection = .project(id: item.id)
    state.deletingProjectID = item.id
    state.alert = AlertState {
      TextState("'\(item.name)' 프로젝트를 삭제할까요?")
    } actions: {
      ButtonState(role: .destructive, action: .confirmDelete) { TextState("삭제") }
      ButtonState(role: .cancel) { TextState("취소") }
    } message: {
      TextState("프로젝트에 속한 Secret과의 연결이 해제됩니다. Secret 자체는 삭제되지 않습니다.")
    }

    let store = TestStore(initialState: state) {
      SidebarFeature()
    } withDependencies: {
      $0.sidebarClient.deleteProject = { _ in }
      $0.sidebarClient.fetchProjects = { [] }
    }

    await store.send(.alert(.presented(.confirmDelete))) {
      $0.deletingProjectID = nil
      $0.alert = nil
    }
    await store.receive(.deleteResponse(.success(item.id))) {
      $0.selection = .filter(.all)
    }
    await store.receive(.delegate(.selectionChanged(.filter(.all))))
    await store.receive(.task) {
      $0.projectsState = .loading
    }
    await store.receive(.projectsResponse(.success([]))) {
      $0.projectsState = .loaded([])
    }
  }
}
