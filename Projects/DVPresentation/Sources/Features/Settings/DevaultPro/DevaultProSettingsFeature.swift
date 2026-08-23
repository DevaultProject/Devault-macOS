// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain

// MARK: - DevaultProSettingsFeature

@Reducer
struct DevaultProSettingsFeature {

  // MARK: - State

  @ObservableState
  struct State: Equatable {
    var subscriptionStatus: SubscriptionStatus = .free
    /// `SubscriptionStatus`엔 productID만 있고 표시명(개월수)이 없어서, 상품 목록에서 따로 찾아온다.
    var currentPlanName: String?
    @Presents var paywall: DevaultProPaywallFeature.State?

    var isPro: Bool { subscriptionStatus.entitlement == .pro }
  }

  // MARK: - Action

  enum Action: Equatable {

    // MARK: - View

    case task
    case didTapUpgrade
    case didTapChangePlan
    case didTapManageSubscription

    // MARK: - Internal

    case statusLoaded(SubscriptionStatus)
    case planNameLoaded(String?)

    // MARK: - Child

    case paywall(PresentationAction<DevaultProPaywallFeature.Action>)
  }

  // MARK: - Dependencies

  @Dependency(\.purchaseClient) var purchaseClient
  @Dependency(\.entitlementClient) var entitlementClient

  // MARK: - Body

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        // 환불·복원·구매로 등급이 바뀔 때마다 다시 읽는다. 스트림이 구독 즉시 현재값을
        // 한 번 방출하므로 최초 로드도 이 하나로 해결된다.
        return .run { send in
          for await _ in entitlementClient.stream() {
            let status = await purchaseClient.subscriptionStatus()
            await send(.statusLoaded(status))
          }
        }

      case .statusLoaded(let status):
        state.subscriptionStatus = status
        guard let productID = status.productID else {
          state.currentPlanName = nil
          return .none
        }
        return .run { send in
          let name = try? await purchaseClient.products().first { $0.id == productID }?.displayName
          await send(.planNameLoaded(name))
        }

      case .planNameLoaded(let name):
        state.currentPlanName = name
        return .none

      case .didTapUpgrade, .didTapChangePlan:
        state.paywall = DevaultProPaywallFeature.State()
        return .none

      case .didTapManageSubscription:
        return .run { _ in purchaseClient.openManageSubscriptions() }

      case .paywall(.presented(.delegate(.didFinish))):
        state.paywall = nil
        return reloadStatus()

      case .paywall(.dismiss):
        // 같은 등급(Pro) 안에서 플랜만 바꾼 경우 등급 스트림이 반응하지 않는다 — 등급 값 자체는
        // 안 바뀌어서 갱신 이벤트가 없다. 페이월을 닫는 시점에 한 번 더 읽어 갱신일·플랜을 맞춘다.
        return reloadStatus()

      case .paywall:
        return .none
      }
    }
    .ifLet(\.$paywall, action: \.paywall) {
      DevaultProPaywallFeature()
    }
  }

  private func reloadStatus() -> Effect<Action> {
    .run { send in
      let status = await purchaseClient.subscriptionStatus()
      await send(.statusLoaded(status))
    }
  }
}
