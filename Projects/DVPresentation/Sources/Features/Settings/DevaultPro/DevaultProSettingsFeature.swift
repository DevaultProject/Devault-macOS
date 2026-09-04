// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain

// MARK: - DevaultProSettingsFeature

@Reducer
public struct DevaultProSettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var subscriptionStatus: SubscriptionStatus = .free
    /// `SubscriptionStatus`엔 productID만 있고 표시명(개월수)이 없어서, 상품 목록에서 따로 찾아온다.
    var currentPlanName: String?
    /// 다음 갱신에 적용될 플랜의 표시명. **변경 예약이 있을 때만** 채워지고, 그 외엔 nil이다.
    var renewalPlanName: String?
    /// 무료 사용량 표시("N/15개 사용")용. Pro는 화면에서 안 쓰지만 등급 전환 순간을 대비해 항상 읽어 둔다.
    var secretCount: Int?
    /// 수동 새로고침 진행 중. `Transaction.updates`가 아직 반영 전이라 등급이 실제와
    /// 다르게 보일 때, 사용자가 재시작 대신 누를 수 있는 탈출구를 위한 상태다.
    var isRefreshing = false
    @Presents var paywall: DevaultProPaywallFeature.State?

    var isPro: Bool { subscriptionStatus.entitlement == .pro }

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task
    case didTapUpgrade
    case didTapChangePlan
    case didTapManageSubscription
    case didTapRefresh

    // MARK: - Internal

    case statusLoaded(SubscriptionStatus)
    case planNamesLoaded(current: String?, renewal: String?)
    case secretCountLoaded(Int)

    // MARK: - Child

    case paywall(PresentationAction<DevaultProPaywallFeature.Action>)
  }

  // MARK: - Dependencies

  @Dependency(\.purchaseClient) var purchaseClient
  @Dependency(\.entitlementClient) var entitlementClient
  @Dependency(\.secretClient) var secretClient

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        // 환불·복원·구매로 등급이 바뀔 때마다 다시 읽는다. 스트림이 구독 즉시 현재값을
        // 한 번 방출하므로 최초 로드도 이 하나로 해결된다.
        return .merge(
          .run { send in
            for await _ in entitlementClient.stream() {
              let status = await purchaseClient.subscriptionStatus()
              await send(.statusLoaded(status))
            }
          },
          // 화면을 열 때 한 번만 읽는다. 생성·삭제 때마다 실시간으로 따라올 필요는 없는
          // 참고용 사용량 표시다.
          .run { send in
            if let count = try? await secretClient.totalCountExcludingTrash() {
              await send(.secretCountLoaded(count))
            }
          }
        )

      case .didTapRefresh:
        state.isRefreshing = true
        return .run { send in
          await purchaseClient.refreshEntitlement()
          let status = await purchaseClient.subscriptionStatus()
          await send(.statusLoaded(status))
        }

      case .statusLoaded(let status):
        state.isRefreshing = false
        state.subscriptionStatus = status
        guard let productID = status.productID else {
          state.currentPlanName = nil
          state.renewalPlanName = nil
          return .none
        }
        // 변경 예약이 있을 때(다음 갱신 상품이 현재와 다를 때)만 예약 플랜명을 함께 해석한다.
        let renewalID = status.hasPendingPlanChange ? status.renewalProductID : nil
        return .run { send in
          let products = try? await purchaseClient.products()
          let current = products?.first { $0.id == productID }?.displayName
          let renewal = renewalID.flatMap { id in products?.first { $0.id == id }?.displayName }
          await send(.planNamesLoaded(current: current, renewal: renewal))
        }

      case let .planNamesLoaded(current, renewal):
        state.currentPlanName = current
        state.renewalPlanName = renewal
        return .none

      case .secretCountLoaded(let count):
        state.secretCount = count
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
