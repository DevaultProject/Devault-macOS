// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

// MARK: - CreateProjectFeature

@Reducer
public struct CreateProjectFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    public internal(set) var name = ""
    public internal(set) var isCreating = false
    @Presents var alert: AlertState<Action.Alert>?

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case didChangeName(String)
    case didTapCreate
    case didTapCancel

    // MARK: - Internal

    case createResponse(Result<ProjectItem, SidebarError>)

    // MARK: - Child

    case alert(PresentationAction<Alert>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case projectCreated(ProjectItem)
    }

    public enum Alert: Equatable {}
  }

  // MARK: - Dependencies

  @Dependency(\.sidebarClient) var sidebarClient
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
            let item = try await sidebarClient.createProject(trimmedName)
            await send(.createResponse(.success(item)))
          } catch let error as SidebarError {
            await send(.createResponse(.failure(error)))
          } catch {
            await send(.createResponse(.failure(.createFailed)))
          }
        }

      case .createResponse(.success(let item)):
        state.isCreating = false
        return .run { send in
          await send(.delegate(.projectCreated(item)))
          await dismiss()
        }

      case .createResponse(.failure(.nameTaken)):
        state.isCreating = false
        state.alert = makeCreateNameTakenAlert()
        return .none

      case .createResponse(.failure):
        state.isCreating = false
        state.alert = makeCreateFailedAlert()
        return .none

      case .didTapCancel:
        return .run { _ in await dismiss() }

      case .alert:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

// MARK: - Private

private extension CreateProjectFeature {

  func makeCreateNameTakenAlert() -> AlertState<Action.Alert> {
    AlertState {
      TextState(String.module("This project name is already in use."))
    } actions: {
      ButtonState(role: .cancel) { TextState(String.module("OK")) }
    } message: {
      TextState(String.module("Please enter a different name."))
    }
  }

  func makeCreateFailedAlert() -> AlertState<Action.Alert> {
    AlertState {
      TextState(String.module("Couldn't create the project."))
    } actions: {
      ButtonState(role: .cancel) { TextState(String.module("OK")) }
    } message: {
      TextState(String.module("Please try again in a moment."))
    }
  }
}
