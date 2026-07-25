// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

// MARK: - AddToProjectFeature

@Reducer
public struct AddToProjectFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public let secretID: Secret.ID
    public internal(set) var projectsState: LoadingState<IdentifiedArrayOf<ProjectItem>, SidebarError> = .idle
    public internal(set) var selectedProjectID: ProjectItem.ID?
    @Presents var destination: Destination.State?
    @Presents var alert: AlertState<Action.Alert>?

    public init(secretID: Secret.ID) {
      self.secretID = secretID
    }
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task
    case didSelectProject(id: ProjectItem.ID?)
    case didTapCreateNewProject
    case didTapDone
    case didTapCancel

    // MARK: - Internal

    case projectsResponse(Result<[ProjectItem], SidebarError>)
    case linkResponse(Result<Secret.ID, SecretUseCaseError>)

    // MARK: - Child

    case destination(PresentationAction<Destination.Action>)
    case alert(PresentationAction<Alert>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case projectLinked
    }

    public enum Alert: Equatable {}
  }

  // MARK: - Destination

  @Reducer
  public enum Destination {
    case createProject(CreateProjectFeature)
  }

  // MARK: - Dependencies

  @Dependency(\.sidebarClient) var sidebarClient
  @Dependency(\.secretClient) var secretClient
  @Dependency(\.dismiss) var dismiss

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

      case .projectsResponse(.success(let projects)):
        state.projectsState = .loaded(IdentifiedArray(uniqueElements: projects))
        return .none

      case .projectsResponse(.failure(let error)):
        state.projectsState = .failed(error)
        return .none

      case .didSelectProject(let id):
        state.selectedProjectID = id
        return .none

      case .didTapCreateNewProject:
        state.destination = .createProject(CreateProjectFeature.State())
        return .none

      case .destination(.presented(.createProject(.delegate(.projectCreated(let item))))):
        var projects: IdentifiedArrayOf<ProjectItem> = {
          if case let .loaded(projects) = state.projectsState { return projects }
          return []
        }()
        projects.append(item)
        state.projectsState = .loaded(projects)
        state.selectedProjectID = item.id
        return .none

      case .destination:
        return .none

      case .didTapDone:
        guard let projectID = state.selectedProjectID else {
          return .none
        }
        return .run { [secretID = state.secretID] send in
          do {
            try await secretClient.linkProject(secretID, projectID)
            await send(.linkResponse(.success(secretID)))
          } catch {
            await send(.linkResponse(.failure(SecretUseCaseError.map(error))))
          }
        }

      case .linkResponse(.success):
        return .run { send in
          await send(.delegate(.projectLinked))
          await dismiss()
        }

      case .linkResponse(.failure):
        state.alert = AlertState {
          TextState("프로젝트에 추가하지 못했어요")
        } actions: {
          ButtonState(role: .cancel) { TextState("확인") }
        } message: {
          TextState("잠시 후 다시 시도해주세요.")
        }
        return .none

      case .didTapCancel:
        return .run { _ in await dismiss() }

      case .alert:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
    .ifLet(\.$alert, action: \.alert)
  }
}

// MARK: - Destination Equatable

// swift-composable-architecture는 @Reducer enum의 State/Action에 Equatable을 자동으로 붙이지 않는다.
extension AddToProjectFeature.Destination.State: Equatable {}
extension AddToProjectFeature.Destination.Action: Equatable {}
