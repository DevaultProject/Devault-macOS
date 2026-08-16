// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - MainFeature

@Reducer
public struct MainFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var sidebar: SidebarFeature.State = .init()
    var secretList: SecretListFeature.State = .init(collection: .all)
    /// sheet가 아닌 2-column NavigationSplitView 전환 용도이므로 @Presents 미사용
    var selectSecretType: SelectSecretTypeFeature.State?
    @Presents var createProject: CreateProjectFeature.State?
    /// sheet가 아닌 2-column NavigationSplitView 전환 용도이므로 @Presents 미사용
    var createSecret: CreateSecretFeature.State?
    /// sheet가 아닌 3-column NavigationSplitView detail 컬럼 용도이므로 @Presents 미사용
    var secretDetail: SecretDetailFeature.State?
    /// 별도 Window가 아니라 콘텐츠 스위칭으로 처리하므로 @Presents 미사용
    var settings: SettingsFeature.State?

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task
    case didTapLock

    // MARK: - Internal

    case iCloudRemoteChangeDetected

    // MARK: - Child

    case sidebar(SidebarFeature.Action)
    case secretList(SecretListFeature.Action)
    case selectSecretType(SelectSecretTypeFeature.Action)
    case createProject(PresentationAction<CreateProjectFeature.Action>)
    case createSecret(CreateSecretFeature.Action)
    case secretDetail(SecretDetailFeature.Action)
    case settings(SettingsFeature.Action)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case lockRequested
    }
  }

  // MARK: - Dependencies

  @Dependency(\.date.now) var now

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Scope(state: \.sidebar, action: \.sidebar) {
      SidebarFeature()
    }
    Scope(state: \.secretList, action: \.secretList) {
      SecretListFeature()
    }
    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .task:
        return .none

      case .iCloudRemoteChangeDetected:
        return .concatenate(
          .send(.secretList(.refresh)),
          .send(.sidebar(.task))
        )

      case .didTapLock:
        return .send(.delegate(.lockRequested))

      case .sidebar(.delegate(let delegate)):
        return handleSidebarDelegate(&state, delegate: delegate)

      case .sidebar:
        return .none

      case .settings(.delegate(.closeRequested)):
        state.settings = nil
        return .none

      case .settings(.delegate(.storageDidSwitch)),
           .settings(.delegate(.vaultDataReset)):
        resetVaultContent(&state)
        return .concatenate(
          .send(.secretList(.refresh)),
          .send(.sidebar(.task))
        )

      case .settings:
        return .none

      case .secretList(.delegate(.secretSelected(let id))):
        if let id, case .loaded(let secrets) = state.secretList.secretsState, let secret = secrets[id: id] {
          state.secretDetail = SecretDetailFeature.State(secret: secret)
        } else {
          state.secretDetail = nil
        }
        return .none

      // 자식끼리 직접 연결하지 않고 공통 부모가 사이드바 개수 갱신을 지시한다 (TCA_GUIDELINES 7.4).
      case .secretList(.delegate(.secretsChanged)):
        return .send(.sidebar(.countsRefreshRequested))

      case .secretList:
        return .none

      case .secretDetail(.delegate(.closed)):
        state.secretDetail = nil
        state.secretList.selectedSecretID = nil
        return .none

      // 즐겨찾기·저장으로 Secret이 바뀌면 목록을 재조회한다. 단순 항목 교체로는
      // liked / expired / project 같은 필터 컬렉션에서 조건을 벗어난 항목이 남는다.
      //
      // 사이드바 개수도 함께 지시한다. `.refresh`는 목록만 다시 읽고 `.secretsChanged`를
      // 발신하지 않으므로(그 delegate는 `.mutationResponse` 성공 경로에서만 나온다) 개수가
      // 그대로 남는다 — 즐겨찾기는 Starred, 삭제는 All·Deleted 개수를 바꾼다.
      // `.merge`는 도착 순서를 보장하지 않아 테스트가 깨지기 쉬우므로 순차 실행한다.
      case .secretDetail(.delegate(.secretUpdated)):
        return .concatenate(
          .send(.secretList(.refresh)),
          .send(.sidebar(.countsRefreshRequested))
        )

      case .secretDetail(.delegate(.deleted)):
        state.secretDetail = nil
        state.secretList.selectedSecretID = nil
        return .concatenate(
          .send(.secretList(.refresh)),
          .send(.sidebar(.countsRefreshRequested))
        )

      // 자식끼리 직접 연결하지 않고 공통 부모가 사이드바 재조회를 지시한다 (TCA_GUIDELINES 7.4).
      // 아래 `.secretDetail` 캐치올보다 **앞에** 둬야 한다 — 뒤에 두면 그쪽이 먼저 잡아 무시된다.
      case .secretDetail(.delegate(.projectsChanged)):
        return .send(.sidebar(.refresh))

      case .secretDetail:
        return .none

      case .selectSecretType(.delegate(.typeSelected(let secretType))):
        state.createSecret = CreateSecretFeature.State(secretType: secretType)
        return .none

      case .selectSecretType:
        return .none

      case .createSecret(.delegate(.secretCreated(_))):
        state.createSecret = nil
        state.selectSecretType = nil
        // `.merge`는 도착 순서를 보장하지 않아 테스트가 깨지기 쉬우므로 순차 실행한다.
        return .concatenate(
          .send(.sidebar(.setCreatingSecret(false))),
          .send(.sidebar(.countsRefreshRequested))
        )

      // 자식끼리 직접 연결하지 않고 공통 부모가 사이드바 재조회를 지시한다 (TCA_GUIDELINES 7.4).
      case .createSecret(.delegate(.projectsChanged)):
        return .send(.sidebar(.refresh))

      case .createSecret(.delegate(.cancelled)):
        state.createSecret = nil
        state.selectSecretType = .init()
        return .none

      case .createSecret:
        return .none

      case .createProject(.presented(.delegate(.projectCreated(let item)))):
        state.createProject = nil
        if !state.sidebar.isCreatingSecret {
          state.sidebar.selection = .project(id: item.id)
          state.secretList = .init(collection: .project(id: item.id), projectName: item.name)
        }
        return .send(.sidebar(.refresh))

      case .createProject:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.selectSecretType, action: \.selectSecretType) {
      SelectSecretTypeFeature()
    }
    .ifLet(\.$createProject, action: \.createProject) {
      CreateProjectFeature()
    }
    .ifLet(\.createSecret, action: \.createSecret) {
      CreateSecretFeature()
    }
    .ifLet(\.secretDetail, action: \.secretDetail) {
      SecretDetailFeature()
    }
    .ifLet(\.settings, action: \.settings) {
      SettingsFeature()
    }
  }
}

// MARK: - Private

extension MainFeature {

  private func handleSidebarDelegate(
    _ state: inout State,
    delegate: SidebarFeature.Action.Delegate
  ) -> Effect<Action> {
    switch delegate {
    case .selectionChanged(let selection):
      state.selectSecretType = nil
      state.createSecret = nil
      state.secretDetail = nil
      state.secretList = makeSecretListState(selection: selection, projects: state.sidebar.projects)
      return .send(.sidebar(.setCreatingSecret(false)))

    case .addButtonTapped:
      state.createSecret = nil
      state.selectSecretType = .init()
      // 생성 플로우로 들어가면 조회 중이던 시크릿을 놓는다. 생성 중에는 2컬럼이라 상세가
      // 화면에서 사라지지만 State는 살아남으므로, 정리하지 않으면 생성을 마치고 3컬럼으로
      // 돌아올 때 이전 시크릿 상세가 다시 나타나고 `.task(id:)`가 Touch ID까지 다시 요구한다.
      state.secretDetail = nil
      state.secretList.selectedSecretID = nil
      return .send(.sidebar(.setCreatingSecret(true)))

    case .addProjectTapped:
      state.createProject = .init()
      return .none

    case .settingsTapped:
      state.settings = .init()
      return .none

    case .projectRenamed(let item):
      if case .project(id: item.id) = state.sidebar.selection {
        state.secretList = .init(collection: .project(id: item.id), projectName: item.name)
      }
      return .none
    }
  }

  private func makeSecretListState(
    selection: SidebarSelection,
    projects: IdentifiedArrayOf<ProjectItem>
  ) -> SecretListFeature.State {
    switch selection {
    case .filter(.all):
      return .init(collection: .all)
    case .filter(.starred):
      return .init(collection: .liked)
    case .filter(.notice):
      return .init(collection: .notice(referenceDate: now))
    case .filter(.expired):
      return .init(collection: .expired(referenceDate: now))
    case .filter(.deleted):
      return .init(collection: .deleted)
    case .project(id: let id):
      let projectName = projects[id: id]?.name
      return .init(collection: .project(id: id), projectName: projectName)
    }
  }

  /// 활성 저장소의 내용이 교체되거나 초기화됐을 때 이전 저장소에서 파생된 화면 상태를 버린다.
  private func resetVaultContent(_ state: inout State) {
    state.selectSecretType = nil
    state.createProject = nil
    state.createSecret = nil
    state.secretDetail = nil
    state.sidebar.isCreatingSecret = false
    state.sidebar.selection = .filter(.all)
    state.secretList = .init(collection: .all)
  }
}
