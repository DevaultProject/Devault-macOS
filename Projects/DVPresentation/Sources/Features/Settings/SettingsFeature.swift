// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - SettingsFeature

@Reducer
public struct SettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var selectedCategory: SettingsCategory = .general
    var general = GeneralSettingsFeature.State()
    var security = SecuritySettingsFeature.State()
    var icloud = ICloudSettingsFeature.State()
    var notifications = NotificationSettingsFeature.State()

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case didSelectCategory(SettingsCategory)
    case didTapClose

    // MARK: - Child

    case general(GeneralSettingsFeature.Action)
    case security(SecuritySettingsFeature.Action)
    case icloud(ICloudSettingsFeature.Action)
    case notifications(NotificationSettingsFeature.Action)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case closeRequested
    }
  }

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Scope(state: \.general, action: \.general) {
      GeneralSettingsFeature()
    }
    Scope(state: \.security, action: \.security) {
      SecuritySettingsFeature()
    }
    Scope(state: \.icloud, action: \.icloud) {
      ICloudSettingsFeature()
    }
    Scope(state: \.notifications, action: \.notifications) {
      NotificationSettingsFeature()
    }
    Reduce { state, action in
      switch action {
      case .didSelectCategory(let category):
        state.selectedCategory = category
        return .none

      case .didTapClose:
        return .send(.delegate(.closeRequested))

      case .general:
        return .none

      case .security:
        return .none

      case .icloud:
        return .none

      case .notifications:
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
