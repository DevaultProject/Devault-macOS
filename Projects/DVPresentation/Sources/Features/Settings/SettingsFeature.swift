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
    var data = DataSettingsFeature.State()
    var about = AboutSettingsFeature.State()

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case didTapClose

    // MARK: - Child

    case general(GeneralSettingsFeature.Action)
    case security(SecuritySettingsFeature.Action)
    case icloud(ICloudSettingsFeature.Action)
    case notifications(NotificationSettingsFeature.Action)
    case data(DataSettingsFeature.Action)
    case about(AboutSettingsFeature.Action)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      case closeRequested
      case storageDidSwitch
      case vaultDataReset
    }
  }

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
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
    Scope(state: \.data, action: \.data) {
      DataSettingsFeature()
    }
    Scope(state: \.about, action: \.about) {
      AboutSettingsFeature()
    }
    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .didTapClose:
        return .send(.delegate(.closeRequested))

      case .general:
        return .none

      case .security:
        return .none

      case .icloud(.delegate(.storageDidSwitch)):
        return .send(.delegate(.storageDidSwitch))

      case .icloud:
        return .none

      case .notifications:
        return .none

      case .data(.delegate(.dataDeleted)):
        return .send(.delegate(.vaultDataReset))

      case .data:
        return .none

      case .about:
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
