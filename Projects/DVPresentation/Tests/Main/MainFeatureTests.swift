// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("MainFeature")
struct MainFeatureTests {

  /// 사이드바 카운트 집계의 기준 시각을 고정한다.
  static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

  // MARK: - Count Refresh

  @Test("secretList의 secretsChanged 델리게이트는 사이드바 카운트를 다시 세게 한다")
  func secretsChangedRefreshesSidebarCounts() async {
    let item = ProjectItem(id: UUID(), name: "Backend")
    let counts = SecretCounts(byFilter: [.all: 3], byProject: [item.id: 1])

    var initial = MainFeature.State()
    initial.sidebar.projectsState = .loaded([item])

    let store = TestStore(initialState: initial) {
      MainFeature()
    } withDependencies: {
      $0.sidebarClient.fetchCounts = { _, projectIDs in
        #expect(projectIDs == [item.id])
        return counts
      }
      $0.date = .constant(Self.referenceDate)
    }

    await store.send(.secretList(.delegate(.secretsChanged)))
    await store.receive(.sidebar(.countsRefreshRequested)) {
      $0.sidebar.countsState = .loading
    }
    await store.receive(.sidebar(.countsResponse(.success(counts)))) {
      $0.sidebar.countsState = .loaded(counts)
    }
  }

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

  // MARK: - CreateSecret Routing

  @Test("typeSelected는 createSecret State를 세팅한다")
  func typeSelectedSetsCreateSecret() async {
    var initial = MainFeature.State()
    initial.selectSecretType = .init()

    let store = TestStore(initialState: initial) {
      MainFeature()
    }

    await store.send(.selectSecretType(.delegate(.typeSelected(.apiKeyToken)))) {
      $0.createSecret = CreateSecretFeature.State(secretType: .apiKeyToken)
    }
  }

  @Test("secretCreated는 생성 플로우를 닫고 사이드바 카운트를 다시 세게 한다")
  func secretCreatedClearsCreationFlow() async {
    let secretID = UUID()
    let counts = SecretCounts(byFilter: [.all: 1], byProject: [:])
    var initial = MainFeature.State()
    initial.selectSecretType = .init()
    initial.createSecret = CreateSecretFeature.State(secretType: .apiKeyToken)
    initial.sidebar.isCreatingSecret = true

    let store = TestStore(initialState: initial) {
      MainFeature()
    } withDependencies: {
      $0.sidebarClient.fetchCounts = { _, _ in counts }
      $0.date = .constant(Self.referenceDate)
    }

    await store.send(.createSecret(.delegate(.secretCreated(secretID)))) {
      $0.createSecret = nil
      $0.selectSecretType = nil
    }
    await store.receive(.sidebar(.setCreatingSecret(false))) {
      $0.sidebar.isCreatingSecret = false
    }
    await store.receive(.sidebar(.countsRefreshRequested)) {
      $0.sidebar.countsState = .loading
    }
    await store.receive(.sidebar(.countsResponse(.success(counts)))) {
      $0.sidebar.countsState = .loaded(counts)
    }
  }

  @Test("cancelled는 createSecret을 닫고 selectSecretType을 초기화해 타입 선택으로 돌아간다")
  func cancelledResetsToTypeSelection() async {
    var initial = MainFeature.State()
    initial.selectSecretType = .init()
    initial.createSecret = CreateSecretFeature.State(secretType: .apiKeyToken)

    let store = TestStore(initialState: initial) {
      MainFeature()
    }

    await store.send(.createSecret(.delegate(.cancelled))) {
      $0.createSecret = nil
      $0.selectSecretType = .init()
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
      $0.sidebarClient.fetchCounts = { _, _ in SecretCounts() }
      $0.date = .constant(Self.referenceDate)
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
      $0.sidebar.countsState = .loading
    }
    await store.receive(.sidebar(.projectsResponse(.success([item])))) {
      $0.sidebar.projectsState = .loaded([item])
    }
    await store.receive(.sidebar(.countsResponse(.success(SecretCounts())))) {
      $0.sidebar.countsState = .loaded(SecretCounts())
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
      $0.sidebarClient.fetchCounts = { _, _ in SecretCounts() }
      $0.date = .constant(Self.referenceDate)
    }

    await store.send(.createProject(.presented(.delegate(.projectCreated(item))))) {
      $0.createProject = nil
      // selection 및 secretList 변경 없음
    }
    await store.receive(.sidebar(.task)) {
      $0.sidebar.projectsState = .loading
      $0.sidebar.countsState = .loading
    }
    await store.receive(.sidebar(.projectsResponse(.success([item])))) {
      $0.sidebar.projectsState = .loaded([item])
    }
    await store.receive(.sidebar(.countsResponse(.success(SecretCounts())))) {
      $0.sidebar.countsState = .loaded(SecretCounts())
    }
  }

  // MARK: - SecretDetail Routing

  @Test("secretSelected(id)는 해당 Secret으로 secretDetail을 세팅한다")
  func secretSelectedSetsSecretDetail() async {
    let secret = Secret(
      id: UUID(),
      name: "Test Token",
      secretType: .apiKeyToken,
      createdAt: Date(),
      updatedAt: Date(),
      payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
    )

    var initial = MainFeature.State()
    initial.secretList.secretsState = .loaded([secret])

    let store = TestStore(initialState: initial) {
      MainFeature()
    }

    await store.send(.secretList(.didSelectSecret(id: secret.id))) {
      $0.secretList.selectedSecretID = secret.id
    }
    await store.receive(.secretList(.delegate(.secretSelected(secret.id)))) {
      $0.secretDetail = SecretDetailFeature.State(secret: secret)
    }
  }

  @Test("secretSelected(nil)은 secretDetail을 닫는다")
  func secretSelectedNilClearsSecretDetail() async {
    let secret = Secret(
      id: UUID(),
      name: "Test Token",
      secretType: .apiKeyToken,
      createdAt: Date(),
      updatedAt: Date(),
      payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
    )

    var initial = MainFeature.State()
    initial.secretList.secretsState = .loaded([secret])
    initial.secretList.selectedSecretID = secret.id
    initial.secretDetail = SecretDetailFeature.State(secret: secret)

    let store = TestStore(initialState: initial) {
      MainFeature()
    }

    await store.send(.secretList(.didSelectSecret(id: nil))) {
      $0.secretList.selectedSecretID = nil
    }
    await store.receive(.secretList(.delegate(.secretSelected(nil)))) {
      $0.secretDetail = nil
    }
  }

  @Test("secretDetail closed delegate는 secretDetail과 selectedSecretID를 초기화한다")
  func secretDetailClosedClearsDetail() async {
    let secret = Secret(
      id: UUID(),
      name: "Test Token",
      secretType: .apiKeyToken,
      createdAt: Date(),
      updatedAt: Date(),
      payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
    )

    var initial = MainFeature.State()
    initial.secretList.selectedSecretID = secret.id
    initial.secretDetail = SecretDetailFeature.State(secret: secret)

    let store = TestStore(initialState: initial) {
      MainFeature()
    }

    await store.send(.secretDetail(.delegate(.closed))) {
      $0.secretDetail = nil
      $0.secretList.selectedSecretID = nil
    }
  }

  @Test("secretUpdated delegate는 목록을 재조회한다")
  func secretUpdatedRefreshesList() async {
    let secret = Secret(
      id: UUID(),
      name: "Test Token",
      secretType: .apiKeyToken,
      liked: true,
      createdAt: Date(),
      updatedAt: Date(),
      payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
    )

    var initial = MainFeature.State()
    initial.secretList.selectedSecretID = secret.id
    initial.secretDetail = SecretDetailFeature.State(secret: secret)

    let store = TestStore(initialState: initial) {
      MainFeature()
    } withDependencies: {
      $0.secretClient.fetchByQuery = { _ in [secret] }
    }

    await store.send(.secretDetail(.delegate(.secretUpdated(secret))))
    // refresh는 .loading으로 바꾸지 않는다 — 목록이 깜빡이지 않아야 한다.
    await store.receive(.secretList(.refresh))
    await store.receive(.secretList(.secretsResponse(.success([secret])))) {
      $0.secretList.secretsState = .loaded(IdentifiedArray(uniqueElements: [secret]))
    }
    // detail은 유지된다 — 즐겨찾기 토글로 화면이 닫히면 안 된다.
    #expect(store.state.secretDetail != nil)
  }

  @Test("deleted delegate는 detail을 닫고 목록을 재조회한다")
  func secretDeletedClosesDetailAndRefreshes() async {
    let secret = Secret(
      id: UUID(),
      name: "Test Token",
      secretType: .apiKeyToken,
      createdAt: Date(),
      updatedAt: Date(),
      payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
    )

    var initial = MainFeature.State()
    initial.secretList.selectedSecretID = secret.id
    initial.secretDetail = SecretDetailFeature.State(secret: secret)

    let store = TestStore(initialState: initial) {
      MainFeature()
    } withDependencies: {
      $0.secretClient.fetchByQuery = { _ in [] }
    }

    await store.send(.secretDetail(.delegate(.deleted(secret.id)))) {
      $0.secretDetail = nil
      $0.secretList.selectedSecretID = nil
    }
    await store.receive(.secretList(.refresh))
    await store.receive(.secretList(.secretsResponse(.success([])))) {
      $0.secretList.secretsState = .loaded([])
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
      $0.sidebarClient.fetchCounts = { _, _ in SecretCounts() }
      $0.date = .constant(Self.referenceDate)
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
      $0.sidebar.countsState = .loading
    }
    await store.receive(.sidebar(.projectsResponse(.success([renamed])))) {
      $0.sidebar.projectsState = .loaded([renamed])
    }
    await store.receive(.sidebar(.countsResponse(.success(SecretCounts())))) {
      $0.sidebar.countsState = .loaded(SecretCounts())
    }
  }
}
