// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import SwiftUI

// MARK: - MainFeature

@Reducer
public struct MainFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public var columnVisibility: NavigationSplitViewVisibility = .all
    var sidebar: SidebarFeature.State = .init()
    var secretList: SecretListFeature.State = .init(collection: .all)
    /// sheet가 아닌 2-column NavigationSplitView 전환 용도이므로 @Presents 미사용
    var selectSecretType: SelectSecretTypeFeature.State?
    @Presents var createProject: CreateProjectFeature.State?
    /// sheet가 아닌 2-column NavigationSplitView 전환 용도이므로 @Presents 미사용
    var createSecret: CreateSecretFeature.State?
    /// sheet가 아닌 3-column NavigationSplitView detail 컬럼 용도이므로 @Presents 미사용
    var secretDetail: SecretDetailFeature.State?

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task

    // MARK: - Child

    case sidebar(SidebarFeature.Action)
    case secretList(SecretListFeature.Action)
    case selectSecretType(SelectSecretTypeFeature.Action)
    case createProject(PresentationAction<CreateProjectFeature.Action>)
    case createSecret(CreateSecretFeature.Action)
    case secretDetail(SecretDetailFeature.Action)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {}
  }

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

      case .sidebar(.delegate(let delegate)):
        return handleSidebarDelegate(&state, delegate: delegate)

      case .sidebar:
        return .none

      case .secretList(.delegate(.secretSelected(let id))):
        if let id, case .loaded(let secrets) = state.secretList.secretsState, let secret = secrets[id: id] {
          state.secretDetail = SecretDetailFeature.State(secret: secret)
        } else {
          state.secretDetail = nil
        }
        return .none

      case .secretList:
        return .none

      case .secretDetail(.delegate(.closed)):
        state.secretDetail = nil
        state.secretList.selectedSecretID = nil
        return .none

      case .secretDetail(.delegate(.secretUpdated)):
        return .none

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
        return .send(.sidebar(.setCreatingSecret(false)))

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
        return .send(.sidebar(.task))

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
      state.secretList = makeSecretListState(selection: selection, projects: state.sidebar.projects)
      return .send(.sidebar(.setCreatingSecret(false)))

    case .addButtonTapped:
      state.createSecret = nil
      state.selectSecretType = .init()
      return .send(.sidebar(.setCreatingSecret(true)))

    case .addProjectTapped:
      state.createProject = .init()
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
      // TODO: 도메인 레이어에 .notice collection 추가 후 연결
      return .init(collection: .all)
    case .filter(.expired):
      return .init(collection: .expired(referenceDate: Date()))
    case .filter(.deleted):
      return .init(collection: .deleted)
    case .project(id: let id):
      let projectName = projects[id: id]?.name
      return .init(collection: .project(id: id), projectName: projectName)
    }
  }
}
