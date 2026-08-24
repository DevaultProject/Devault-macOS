// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - SettingsFeature

@Reducer
public struct SettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var selectedCategory: SettingsCategory = .general
    var devaultPro = DevaultProSettingsFeature.State()
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

    // MARK: - Child

    case devaultPro(DevaultProSettingsFeature.Action)
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

  // MARK: - Init

  public init() {}

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Scope(state: \.devaultPro, action: \.devaultPro) {
      DevaultProSettingsFeature()
    }
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

      // `devaultPro` 상태는 사이드바 배지·iCloud 잠금 표시에도 쓰인다(SettingsView).
      // 그 탭을 직접 열지 않아도 최신 등급을 알아야 하므로, 설정 화면이 열리는 시점에
      // 자식의 `.task`를 대신 걸어 등급 스트림 구독을 미리 시작해 둔다.
      case .task:
        return .send(.devaultPro(.task))

      case .didTapClose:
        return .send(.delegate(.closeRequested))

      case .devaultPro:
        return .none

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
