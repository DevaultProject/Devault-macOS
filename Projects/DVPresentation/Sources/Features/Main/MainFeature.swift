// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain

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

    /// 생성 폼의 취소 확인을 기다리는 동안 보관하는 이동 목적지.
    var pendingSelection: SidebarSelection?

    /// 지금 무엇을 그릴지. **화면 분기는 이 값 하나만 본다.**
    /// 뷰에서 optional을 직접 조합하면 같은 판정이 렌더 지점마다 흩어진다.
    var screen: Screen {
      if settings != nil { return .settings }
      if createSecret != nil || selectSecretType != nil { return .creating }
      return .browsing
    }

    /// 서로 배타적인 최상위 화면.
    enum Screen: Equatable {
      case browsing
      case creating
      case settings
    }

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
        exitCreating(&state)
        // `.merge`는 도착 순서를 보장하지 않아 테스트가 깨지기 쉬우므로 순차 실행한다.
        return .concatenate(
          .send(.sidebar(.setCreatingSecret(false))),
          .send(.sidebar(.countsRefreshRequested))
        )

      // 자식끼리 직접 연결하지 않고 공통 부모가 사이드바 재조회를 지시한다 (TCA_GUIDELINES 7.4).
      case .createSecret(.delegate(.projectsChanged)):
        return .send(.sidebar(.refresh))

      // 사이드바가 시작한 취소면 목록으로, 폼의 Cancel이면 타입 그리드로 — 목적지가 다르다.
      case .createSecret(.delegate(.cancelled)):
        guard let pending = state.pendingSelection else {
          state.createSecret = nil
          state.selectSecretType = .init()
          return .none
        }
        state.pendingSelection = nil
        applySelection(pending, &state)
        return .send(.sidebar(.setCreatingSecret(false)))

      // 목적지를 버리지 않으면 다음에 폼의 Cancel을 눌렀을 때 엉뚱하게 목록으로 나간다.
      case .createSecret(.alert(.dismiss)):
        state.pendingSelection = nil
        return .none

      case .createSecret:
        return .none

      case .createProject(.presented(.delegate(.projectCreated(let item)))):
        state.createProject = nil
        // 생성 중이면 목록을 옮기지 않는다 — 마치고 엉뚱한 목록으로 돌아오게 된다.
        if case .browsing = state.sidebar.mode {
          state.sidebar.selection = .project(id: item.id)
          state.secretList.retarget(to: .project(id: item.id), projectName: item.name)
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
    // 폼이 열려 있으면 입력이 있을 수 있으므로 자식의 기존 취소 alert를 거친다.
    // 타입 선택 단계는 입력이 없어 확인 없이 나간다.
    case .selectionChanged(let selection):
      guard state.createSecret == nil else {
        state.pendingSelection = selection
        return .send(.createSecret(.didTapCancel))
      }
      applySelection(selection, &state)
      return .send(.sidebar(.setCreatingSecret(false)))

    case .addButtonTapped:
      enterCreating(&state)
      return .send(.sidebar(.setCreatingSecret(true)))

    case .addProjectTapped:
      state.createProject = .init()
      return .none

    case .settingsTapped:
      state.settings = .init()
      return .none

    // State를 갈아끼우면 목록이 버려지는데 `collection`이 같아 다시 읽지도 않는다.
    case .projectRenamed(let item):
      if case .project(id: item.id) = state.sidebar.selection {
        state.secretList.projectName = item.name
      }
      return .none
    }
  }

  /// 사이드바에서 고른 곳으로 이동한다. 생성 중이었다면 그 플로우를 접는다.
  /// 고른 곳이 이미 보고 있던 곳일 수 있어(생성 중 같은 필터 재선택) `retarget`을 거친다.
  private func applySelection(_ selection: SidebarSelection, _ state: inout State) {
    exitCreating(&state)
    state.secretDetail = nil
    let target = makeCollection(selection: selection, projects: state.sidebar.projects)
    state.secretList.retarget(to: target.collection, projectName: target.projectName)
  }

  /// 생성 플로우로 들어간다. 조회 중이던 시크릿을 함께 놓는다 — 상세 State가 살아남으면
  /// 돌아올 때 되살아나고 `.task(id:)`가 Touch ID까지 다시 요구한다.
  private func enterCreating(_ state: inout State) {
    state.createSecret = nil
    state.selectSecretType = .init()
    state.secretDetail = nil
    state.secretList.selectedSecretID = nil
  }

  /// 생성 플로우를 벗어난다. 한쪽만 남으면 `screen`이 `.creating`으로 판정돼 컬럼이 접힌 채 남는다.
  private func exitCreating(_ state: inout State) {
    state.createSecret = nil
    state.selectSecretType = nil
  }

  /// 교체 여부는 `SecretListFeature.State.retarget(to:projectName:)`이 정하므로 값만 돌려준다.
  private func makeCollection(
    selection: SidebarSelection,
    projects: IdentifiedArrayOf<ProjectItem>
  ) -> (collection: SecretQuery.Collection, projectName: String?) {
    switch selection {
    case .filter(.all):
      return (.all, nil)
    case .filter(.starred):
      return (.liked, nil)
    case .filter(.notice):
      return (.notice(referenceDate: now), nil)
    case .filter(.expired):
      return (.expired(referenceDate: now), nil)
    case .filter(.deleted):
      return (.deleted, nil)
    case .project(id: let id):
      return (.project(id: id), projects[id: id]?.name)
    }
  }

  /// 활성 저장소의 내용이 교체되거나 초기화됐을 때 이전 저장소에서 파생된 화면 상태를 버린다.
  private func resetVaultContent(_ state: inout State) {
    state.selectSecretType = nil
    state.createProject = nil
    state.createSecret = nil
    state.secretDetail = nil
    state.sidebar.mode = .browsing(.filter(.all))
    state.secretList = .init(collection: .all)
  }
}
