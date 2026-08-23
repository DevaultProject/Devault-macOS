// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain

// MARK: - SettingsFeature

@Reducer
public struct SettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var selectedCategory: SettingsCategory = .general
    var isDevaultProSubscribed = false
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
    case task
    case didTapClose

    // MARK: - Internal

    case entitlementChanged(Entitlement)

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
      /// 하위 설정이 게이트에 막혔다. 페이월은 MainFeature가 소유한다.
      case paywallRequired
    }
  }

  // MARK: - Dependencies

  @Dependency(\.entitlementClient) var entitlementClient

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

      case .task:
        return .run { send in
          for await entitlement in entitlementClient.stream() {
            await send(.entitlementChanged(entitlement))
          }
        }

      case .entitlementChanged(let entitlement):
        state.isDevaultProSubscribed = entitlement == .pro
        return .none

      case .didTapClose:
        return .send(.delegate(.closeRequested))

      case .general:
        return .none

      case .security:
        return .none

      case .icloud(.delegate(.paywallRequired)),
           .notifications(.delegate(.paywallRequired)):
        return .send(.delegate(.paywallRequired))

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
