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

  nonisolated static func makeSecret(name: String = "Test Token") -> Secret {
    Secret(
      id: UUID(),
      name: name,
      secretType: .apiKeyToken,
      createdAt: Date(),
      updatedAt: Date(),
      payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
    )
  }

  // MARK: - Screen 판정

  /// 화면 분기가 이 값 하나에 걸려 있다.
  @Test("screen: 아무것도 없으면 browsing")
  func screenDefaultsToBrowsing() {
    #expect(MainFeature.State().screen == .browsing)
  }

  @Test("screen: 타입 선택만 있어도, 폼만 있어도 creating")
  func screenIsCreatingForBothCreationSteps() {
    var selecting = MainFeature.State()
    selecting.selectSecretType = .init()
    #expect(selecting.screen == .creating)

    var form = MainFeature.State()
    form.createSecret = .init(secretType: .apiKeyToken)
    #expect(form.screen == .creating)
  }

  @Test("screen: 설정이 생성보다 우선한다")
  func screenPrefersSettingsOverCreating() {
    var state = MainFeature.State()
    state.selectSecretType = .init()
    state.settings = .init()
    #expect(state.screen == .settings)
  }

  @Test("screen: 상세가 열려 있어도 browsing이다")
  func screenStaysBrowsingWithDetail() {
    var state = MainFeature.State()
    state.secretDetail = .init(secret: Self.makeSecret())
    #expect(state.screen == .browsing)
  }

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
    await store.receive(.sidebar(.countsRefreshRequested))
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

  /// 생성 중에는 2컬럼이라 상세가 화면에서 사라지지만 State는 살아남는다. 정리하지 않으면
  /// 생성을 마치고 3컬럼으로 돌아올 때 이전 상세가 다시 나타나고 Touch ID까지 다시 요구한다.
  @Test("addButtonTapped은 조회 중이던 secretDetail과 목록 선택을 놓는다")
  func addButtonTappedClearsViewingSecret() async {
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

    await store.send(.sidebar(.didTapAddButton))
    await store.receive(.sidebar(.delegate(.addButtonTapped))) {
      $0.selectSecretType = .init()
      $0.secretDetail = nil
      $0.secretList.selectedSecretID = nil
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
    await store.receive(.sidebar(.countsRefreshRequested))
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
    await store.receive(.sidebar(.refresh)) {
      $0.sidebar.isRefreshingProjects = true
    }
    await store.receive(.sidebar(.projectsResponse(.success([item])))) {
      $0.sidebar.isRefreshingProjects = false
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
    await store.receive(.sidebar(.refresh)) {
      $0.sidebar.isRefreshingProjects = true
    }
    await store.receive(.sidebar(.projectsResponse(.success([item])))) {
      $0.sidebar.isRefreshingProjects = false
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

  /// detail State는 nil을 거치지 않고 다른 시크릿으로 교체된다. `ifLet`이 이 전환을 알아보지 못하면
  /// A의 복호화 응답이 B의 State에 실려, 인증한 적 없는 B에 A의 평문과 인증 창이 열린다.
  @Test("시크릿을 바꾸면 이전 시크릿의 복호화 effect가 취소된다")
  func secretSelectedCancelsPreviousRevealEffect() async {
    let secretA = Secret(
      id: UUID(),
      name: "Secret A",
      secretType: .apiKeyToken,
      createdAt: Date(),
      updatedAt: Date(),
      payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
    )
    let secretB = Secret(
      id: UUID(),
      name: "Secret B",
      secretType: .apiKeyToken,
      createdAt: Date(),
      updatedAt: Date(),
      payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
    )

    var initial = MainFeature.State()
    initial.secretList.secretsState = .loaded([secretA, secretB])

    // A의 복호화를 인증 프롬프트가 떠 있는 상태로 붙잡아 둔다.
    let clock = TestClock()

    let store = TestStore(initialState: initial) {
      MainFeature()
    } withDependencies: {
      $0.secretClient.revealPayload = { _, _ in
        try await clock.sleep(for: .seconds(1))
        return .apiKey(APIKeyPayload(value: "A의 평문"), nil)
      }
    }

    await store.send(.secretList(.didSelectSecret(id: secretA.id))) {
      $0.secretList.selectedSecretID = secretA.id
    }
    await store.receive(.secretList(.delegate(.secretSelected(secretA.id)))) {
      $0.secretDetail = SecretDetailFeature.State(secret: secretA)
    }

    await store.send(.secretDetail(.didTapToggleReveal(.value))) {
      $0.secretDetail?.payloadState = .loading
    }

    await store.send(.secretList(.didSelectSecret(id: secretB.id))) {
      $0.secretList.selectedSecretID = secretB.id
    }
    await store.receive(.secretList(.delegate(.secretSelected(secretB.id)))) {
      $0.secretDetail = SecretDetailFeature.State(secret: secretB)
    }

    // A의 복호화가 끝나는 시점. 취소되었다면 아무 액션도 도착하지 않는다 —
    // 도착하면 TestStore가 처리되지 않은 액션으로 실패시킨다.
    await clock.advance(by: .seconds(1))

    #expect(store.state.secretDetail?.secret.id == secretB.id)
    #expect(store.state.secretDetail?.payloadState == .idle)
    #expect(store.state.secretDetail?.revealAuthorizedAt == nil)
    #expect(store.state.secretDetail?.revealedFields.isEmpty == true)
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

  @Test("수정 화면에서 만든 프로젝트는 사이드바에 즉시 반영된다")
  func projectsChangedFromDetailRefreshesSidebar() async {
    let secret = Secret(
      id: UUID(),
      name: "Test Token",
      secretType: .apiKeyToken,
      createdAt: Date(),
      updatedAt: Date(),
      payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
    )
    let created = [ProjectItem(id: UUID(), name: "새 프로젝트")]

    var initial = MainFeature.State()
    initial.secretDetail = SecretDetailFeature.State(secret: secret)

    let store = TestStore(initialState: initial) {
      MainFeature()
    } withDependencies: {
      $0.sidebarClient.fetchProjects = { created }
      $0.sidebarClient.fetchCounts = { _, _ in SecretCounts() }
      $0.date = .constant(Self.referenceDate)
    }

    await store.send(.secretDetail(.delegate(.projectsChanged)))
    await store.receive(.sidebar(.refresh)) {
      $0.sidebar.isRefreshingProjects = true
    }
    await store.receive(.sidebar(.projectsResponse(.success(created)))) {
      $0.sidebar.isRefreshingProjects = false
      $0.sidebar.projectsState = .loaded(IdentifiedArray(uniqueElements: created))
    }
    await store.receive(.sidebar(.countsResponse(.success(SecretCounts())))) {
      $0.sidebar.countsState = .loaded(SecretCounts())
    }
    // 편집 중인 화면은 유지된다 — 프로젝트를 만들었다고 폼이 닫히면 안 된다.
    #expect(store.state.secretDetail != nil)
  }

  @Test("생성 화면에서 만든 프로젝트도 사이드바에 즉시 반영된다")
  func projectsChangedFromCreateRefreshesSidebar() async {
    let created = [ProjectItem(id: UUID(), name: "새 프로젝트")]

    var initial = MainFeature.State()
    initial.createSecret = CreateSecretFeature.State(secretType: .apiKeyToken)

    let store = TestStore(initialState: initial) {
      MainFeature()
    } withDependencies: {
      $0.sidebarClient.fetchProjects = { created }
      $0.sidebarClient.fetchCounts = { _, _ in SecretCounts() }
      $0.date = .constant(Self.referenceDate)
    }

    await store.send(.createSecret(.delegate(.projectsChanged)))
    await store.receive(.sidebar(.refresh)) {
      $0.sidebar.isRefreshingProjects = true
    }
    await store.receive(.sidebar(.projectsResponse(.success(created)))) {
      $0.sidebar.isRefreshingProjects = false
      $0.sidebar.projectsState = .loaded(IdentifiedArray(uniqueElements: created))
    }
    await store.receive(.sidebar(.countsResponse(.success(SecretCounts())))) {
      $0.sidebar.countsState = .loaded(SecretCounts())
    }
    // 생성 폼은 유지된다 — 프로젝트만 만들고 시크릿 작성은 이어가야 한다.
    #expect(store.state.createSecret != nil)
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
      $0.sidebarClient.fetchCounts = { _, _ in SecretCounts() }
      $0.date = .constant(Self.referenceDate)
    }

    await store.send(.secretDetail(.delegate(.secretUpdated(secret))))
    // refresh는 .loading으로 바꾸지 않는다 — 목록이 깜빡이지 않아야 한다.
    await store.receive(.secretList(.refresh))
    // 즐겨찾기는 Starred 개수를 바꾸므로 사이드바 개수도 갱신되어야 한다.
    await store.receive(.sidebar(.countsRefreshRequested))
    await store.receive(.secretList(.secretsResponse(.success([secret])))) {
      $0.secretList.secretsState = .loaded(IdentifiedArray(uniqueElements: [secret]))
    }
    await store.receive(.sidebar(.countsResponse(.success(SecretCounts())))) {
      $0.sidebar.countsState = .loaded(SecretCounts())
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
      $0.sidebarClient.fetchCounts = { _, _ in SecretCounts() }
      $0.date = .constant(Self.referenceDate)
    }

    await store.send(.secretDetail(.delegate(.deleted(secret.id)))) {
      $0.secretDetail = nil
      $0.secretList.selectedSecretID = nil
    }
    await store.receive(.secretList(.refresh))
    // 삭제는 All·Deleted 개수를 바꾸므로 사이드바 개수도 갱신되어야 한다.
    await store.receive(.sidebar(.countsRefreshRequested))
    await store.receive(.secretList(.secretsResponse(.success([])))) {
      $0.secretList.secretsState = .loaded([])
    }
    await store.receive(.sidebar(.countsResponse(.success(SecretCounts())))) {
      $0.sidebar.countsState = .loaded(SecretCounts())
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
    await store.receive(.sidebar(.refresh)) {
      $0.sidebar.isRefreshingProjects = true
    }
    await store.receive(.sidebar(.projectsResponse(.success([renamed])))) {
      $0.sidebar.isRefreshingProjects = false
      $0.sidebar.projectsState = .loaded([renamed])
    }
    await store.receive(.sidebar(.countsResponse(.success(SecretCounts())))) {
      $0.sidebar.countsState = .loaded(SecretCounts())
    }
  }

  // MARK: - Lock

  @Test("didTapLock은 lockRequested를 delegate로 알린다")
  func didTapLockSendsDelegate() async {
    let store = TestStore(initialState: MainFeature.State()) {
      MainFeature()
    }

    await store.send(.didTapLock)
    await store.receive(.delegate(.lockRequested))
  }

  // MARK: - Settings

  @Test("사이드바의 settingsTapped 델리게이트는 settings를 연다")
  func settingsTappedOpensSettings() async {
    let store = TestStore(initialState: MainFeature.State()) {
      MainFeature()
    }

    await store.send(.sidebar(.didTapSettings))
    await store.receive(.sidebar(.delegate(.settingsTapped))) {
      $0.settings = .init()
    }
  }

  @Test("settings의 closeRequested 델리게이트는 settings를 닫는다")
  func settingsCloseRequestedClosesSettings() async {
    var initial = MainFeature.State()
    initial.settings = .init()

    let store = TestStore(initialState: initial) {
      MainFeature()
    }

    await store.send(.settings(.didTapClose))
    await store.receive(.settings(.delegate(.closeRequested))) {
      $0.settings = nil
    }
  }

  @Test("저장소 전환이나 전체 삭제 뒤에는 이전 vault 화면 상태를 버리고 목록을 갱신한다")
  func vaultContentChangeResetsDerivedStateAndRefreshes() async {
    let projectID = UUID()
    var initial = MainFeature.State()
    initial.settings = .init()
    initial.selectSecretType = .init()
    initial.createProject = .init()
    initial.createSecret = .init(secretType: .apiKeyToken)
    initial.sidebar.selection = .project(id: projectID)
    initial.sidebar.isCreatingSecret = true
    initial.secretList = .init(collection: .project(id: projectID), projectName: "Old")

    let store = TestStore(initialState: initial) {
      MainFeature()
    } withDependencies: {
      $0.secretClient.fetchByQuery = { _ in [] }
      $0.sidebarClient.fetchProjects = { [] }
      $0.sidebarClient.fetchCounts = { _, _ in SecretCounts() }
      $0.date = .constant(Self.referenceDate)
    }
    store.exhaustivity = .off(showSkippedAssertions: false)

    await store.send(.settings(.delegate(.vaultDataReset))) {
      $0.selectSecretType = nil
      $0.createProject = nil
      $0.createSecret = nil
      $0.sidebar.selection = .filter(.all)
      $0.sidebar.isCreatingSecret = false
      $0.secretList = .init(collection: .all)
    }
  }
}
