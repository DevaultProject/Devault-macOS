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
    public internal(set) var projects: IdentifiedArrayOf<Project> = []
    public internal(set) var isLoading = false

    public init(secretID: Secret.ID) {
      self.secretID = secretID
    }
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task
    case didTapProject(id: Project.ID)
    case didTapCancel

    // MARK: - Internal

    case projectsResponse(Result<[Project], ProjectUseCaseError>)
    case linkResponse(Result<Secret.ID, SecretUseCaseError>)

    // MARK: - Child

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case projectLinked
    }
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
        state.isLoading = true
        return .run { send in
          do {
            let projects = try await secretClient.fetchProjects()
            await send(.projectsResponse(.success(projects)))
          } catch {
            await send(.projectsResponse(.failure(ProjectUseCaseError.map(error))))
          }
        }

      case .projectsResponse(.success(let projects)):
        state.isLoading = false
        state.projects = IdentifiedArray(uniqueElements: projects)
        return .none

      case .projectsResponse(.failure):
        state.isLoading = false
        return .none

      case .didTapProject(let id):
        return .run { [secretID = state.secretID] send in
          do {
            try await secretClient.linkProject(secretID, id)
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
  }
}
