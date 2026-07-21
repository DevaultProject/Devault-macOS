// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

// MARK: - CreateProjectFeature

@Reducer
public struct CreateProjectFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public internal(set) var name = ""
    public internal(set) var isCreating = false

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case didChangeName(String)
    case didTapCreate
    case didTapCancel

    // MARK: - Internal

    case createResponse(Result<Project, ProjectUseCaseError>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case projectCreated(Project)
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
      case .didChangeName(let name):
        state.name = name
        return .none

      case .didTapCreate:
        let trimmedName = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
          return .none
        }
        state.isCreating = true
        return .run { send in
          do {
            let project = try await secretClient.createProject(trimmedName)
            await send(.createResponse(.success(project)))
          } catch {
            await send(.createResponse(.failure(ProjectUseCaseError.map(error))))
          }
        }

      case .createResponse(.success(let project)):
        state.isCreating = false
        return .run { send in
          await send(.delegate(.projectCreated(project)))
          await dismiss()
        }

      case .createResponse(.failure):
        state.isCreating = false
        return .none

      case .didTapCancel:
        return .run { _ in await dismiss() }

      case .delegate:
        return .none
      }
    }
  }
}
