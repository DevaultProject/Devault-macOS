// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

// MARK: - SidebarFilter

public enum SidebarFilter: Equatable, CaseIterable, Hashable {
  case all
  case starred
  case notice
  case expired
  case deleted

  var title: String {
    switch self {
    case .all:     "All"
    case .starred: "Star"
    case .notice:  "Notice"
    case .expired: "Expired"
    case .deleted: "Deleted"
    }
  }

  var icon: String {
    switch self {
    case .all:     "square.grid.2x2.fill"
    case .starred: "star.fill"
    case .notice:  "exclamationmark"
    case .expired: "clock.badge.xmark"
    case .deleted: "trash"
    }
  }
}

// MARK: - SidebarSelection

public enum SidebarSelection: Equatable {
  case filter(SidebarFilter)
  case project(id: ProjectItem.ID)
}

// MARK: - SidebarFeature

@Reducer
public struct SidebarFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public internal(set) var selection: SidebarSelection = .filter(.all)
    public internal(set) var isProjectSectionExpanded: Bool = true
    public internal(set) var isCreatingSecret: Bool = false
    var projectsState: LoadingState<IdentifiedArrayOf<ProjectItem>, SidebarError> = .idle
    var renamingProjectID: ProjectItem.ID?
    var renameText: String = ""
    var deletingProjectID: ProjectItem.ID?
    @Presents var alert: AlertState<Action.Alert>?

    // computed property — LoadingState에서 추출. 외부 참조(MainFeature, View)에서 LoadingState를 몰라도 됨
    var projects: IdentifiedArrayOf<ProjectItem> {
      if case .loaded(let projects) = projectsState { return projects }
      return []
    }

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task
    case didSelect(SidebarSelection)
    case didTapAddButton
    case didTapSettingsButton
    case didTapAddProject
    case didToggleProjectSection
    case didTapRename(id: ProjectItem.ID)
    case didChangeRenameText(String)
    case didConfirmRename
    case didCancelRename
    case didTapDelete(id: ProjectItem.ID)

    // MARK: - Internal

    case projectsResponse(Result<[ProjectItem], SidebarError>)
    case renameResponse(Result<ProjectItem, SidebarError>)
    case deleteResponse(Result<ProjectItem.ID, SidebarError>)

    // MARK: - Child

    case alert(PresentationAction<Alert>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Alert: Equatable {
      case confirmDelete
    }

    public enum Delegate: Equatable {
      case selectionChanged(SidebarSelection)
      case addButtonTapped
      case settingsButtonTapped
      case addProjectTapped
      case projectRenamed(ProjectItem)
    }
  }

  // MARK: - CancelID (E5)

  private enum CancelID { case fetch }

  // MARK: - Dependencies

  @Dependency(\.sidebarClient) var sidebarClient

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        state.projectsState = .loading
        return .run { send in
          do {
            let projects = try await sidebarClient.fetchProjects()
            await send(.projectsResponse(.success(projects)))
          } catch let error as SidebarError {
            await send(.projectsResponse(.failure(error)))
          } catch {
            await send(.projectsResponse(.failure(.fetchFailed)))
          }
        }
        .cancellable(id: CancelID.fetch, cancelInFlight: true)

      case .projectsResponse(.success(let projects)):
        let sorted = projects.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        state.projectsState = .loaded(IdentifiedArray(uniqueElements: sorted))
        return .none

      case .projectsResponse(.failure(let error)):
        state.projectsState = .failed(error)
        return .none

      case .didSelect(let selection):
        state.selection = selection
        return .send(.delegate(.selectionChanged(selection)))

      case .didTapAddButton:
        return .send(.delegate(.addButtonTapped))

      case .didTapSettingsButton:
        return .send(.delegate(.settingsButtonTapped))

      case .didTapAddProject:
        return .send(.delegate(.addProjectTapped))

      case .didToggleProjectSection:
        state.isProjectSectionExpanded.toggle()
        return .none

      case .didTapRename(id: let id):
        guard let project = state.projects[id: id] else { return .none }
        state.renamingProjectID = id
        state.renameText = project.name
        return .none

      case .didChangeRenameText(let text):
        state.renameText = text
        return .none

      case .didConfirmRename:
        guard let id = state.renamingProjectID else { return .none }
        let name = state.renameText
        state.renamingProjectID = nil
        state.renameText = ""
        return .run { [id, name] send in  // 캡처 리스트 명시
          do {
            let updated = try await sidebarClient.renameProject(id, name)
            await send(.renameResponse(.success(updated)))
          } catch let error as SidebarError {
            await send(.renameResponse(.failure(error)))
          } catch {
            await send(.renameResponse(.failure(.renameFailed)))
          }
        }

      case .didCancelRename:
        state.renamingProjectID = nil
        state.renameText = ""
        return .none

      case .renameResponse(.success(let updated)):
        return .merge(
          .send(.delegate(.projectRenamed(updated))),
          .send(.task)
        )

      case .renameResponse(.failure(.nameTaken)):
        state.alert = AlertState {
          TextState("이미 사용 중인 이름이에요")
        } actions: {
          ButtonState(role: .cancel) { TextState("확인") }
        } message: {
          TextState("다른 프로젝트 이름을 입력해주세요.")
        }
        return .none

      case .renameResponse(.failure):
        return .none

      case .didTapDelete(id: let id):
        guard let project = state.projects[id: id] else { return .none }
        state.deletingProjectID = id
        state.alert = makeDeleteAlert(for: project)  // helper로 분리
        return .none

      case .alert(.presented(.confirmDelete)):
        guard let id = state.deletingProjectID else { return .none }
        state.deletingProjectID = nil
        return .run { [id] send in  // 캡처 리스트 명시
          do {
            try await sidebarClient.deleteProject(id)
            await send(.deleteResponse(.success(id)))
          } catch let error as SidebarError {
            await send(.deleteResponse(.failure(error)))
          } catch {
            await send(.deleteResponse(.failure(.deleteFailed)))
          }
        }

      case .alert:
        return .none

      case .deleteResponse(.success(let id)):
        if state.selection == .project(id: id) {
          state.selection = .filter(.all)
        }
        return .send(.task)

      case .deleteResponse(.failure):
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

// MARK: - Private

private extension SidebarFeature {

  // D3: AlertState 생성 로직 분리
  func makeDeleteAlert(for project: ProjectItem) -> AlertState<Action.Alert> {
    AlertState {
      TextState("'\(project.name)' 프로젝트를 삭제할까요?")
    } actions: {
      ButtonState(role: .destructive, action: .confirmDelete) {
        TextState("삭제")
      }
      ButtonState(role: .cancel) {
        TextState("취소")
      }
    } message: {
      TextState("프로젝트에 속한 Secret과의 연결이 해제됩니다. Secret 자체는 삭제되지 않습니다.")
    }
  }
}
