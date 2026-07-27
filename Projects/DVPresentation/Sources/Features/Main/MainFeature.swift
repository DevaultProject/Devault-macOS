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

      case .secretList:
        return .none

      case .selectSecretType(.delegate(.typeSelected)):
        // TODO: createSecret 연결
        return .none

      case .selectSecretType:
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
      state.secretList = makeSecretListState(selection: selection, projects: state.sidebar.projects)
      return .send(.sidebar(.setCreatingSecret(false)))

    case .addButtonTapped:
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
