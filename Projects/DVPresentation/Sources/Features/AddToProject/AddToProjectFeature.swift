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
    public internal(set) var projectsState: LoadingState<IdentifiedArrayOf<Project>, ProjectUseCaseError> = .idle
    public internal(set) var selectedProjectID: Project.ID?
    @Presents var destination: Destination.State?

    public init(secretID: Secret.ID) {
      self.secretID = secretID
    }
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task
    case didSelectProject(id: Project.ID?)
    case didTapCreateNewProject
    case didTapDone
    case didTapCancel

    // MARK: - Internal

    case projectsResponse(Result<[Project], ProjectUseCaseError>)
    case linkResponse(Result<Secret.ID, SecretUseCaseError>)

    // MARK: - Child

    case destination(PresentationAction<Destination.Action>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case projectLinked
    }
  }

  // MARK: - Destination

  @Reducer
  public enum Destination {
    case createProject(CreateProjectFeature)
  }

  // MARK: - Dependencies

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
            let projects = try await secretClient.fetchProjects()
            await send(.projectsResponse(.success(projects)))
          } catch {
            await send(.projectsResponse(.failure(ProjectUseCaseError.map(error))))
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

      case .destination(.presented(.createProject(.delegate(.projectCreated(let project))))):
        var projects: IdentifiedArrayOf<Project> = {
          if case let .loaded(projects) = state.projectsState { return projects }
          return []
        }()
        projects.append(project)
        state.projectsState = .loaded(projects)
        state.selectedProjectID = project.id
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
        return .none

      case .didTapCancel:
        return .run { _ in await dismiss() }

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

// MARK: - Destination Equatable

// swift-composable-architecture는 @Reducer enum의 State/Action에 Equatable을 자동으로 붙이지 않는다.
extension AddToProjectFeature.Destination.State: Equatable {}
extension AddToProjectFeature.Destination.Action: Equatable {}
