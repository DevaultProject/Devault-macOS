// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain

// MARK: - DevaultProPaywallFeature

@Reducer
public struct DevaultProPaywallFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var products: [SubscriptionProduct] = []
    var selectedProductID: String?
    var isPurchasing = false
    var isRestoring = false
    var errorMessage: String?
    /// 이미 구독 중인 채로 열리면 카피와 버튼 문구가 "가입"이 아니라 "변경"이어야 한다.
    var isChangingPlan = false
    /// 현재 구독 중인 상품 ID. 이 값과 같은 플랜을 선택하면 "변경"이 성립하지 않으므로 버튼을 막는다.
    var currentProductID: String?

    var isBusy: Bool { isPurchasing || isRestoring }
    var selectedProduct: SubscriptionProduct? { products.first { $0.id == selectedProductID } }
    var isSelectingCurrentPlan: Bool { selectedProductID != nil && selectedProductID == currentProductID }

    public init() {}
  }

  // MARK: - Action

  public enum Action: Equatable {

    // MARK: - View

    case task
    case didSelectProduct(String)
    case didTapSubscribe
    case didTapRestore

    // MARK: - Internal

    case statusLoaded(SubscriptionStatus)
    case productsLoaded([SubscriptionProduct])
    case productsLoadFailed
    case purchaseSucceeded
    case purchaseCancelled
    case purchasePending
    case purchaseFailed
    case restoreSucceeded
    case restoreFailed

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      /// 구매/복원이 끝났다(성공). 부모가 시트를 닫는다.
      case didFinish
    }
  }

  // MARK: - Dependencies

  @Dependency(\.purchaseClient) var purchaseClient

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        return .run { send in
          let status = await purchaseClient.subscriptionStatus()
          await send(.statusLoaded(status))
          do {
            let products = try await purchaseClient.products()
            await send(.productsLoaded(products))
          } catch {
            await send(.productsLoadFailed)
          }
        }

      case .statusLoaded(let status):
        state.isChangingPlan = status.entitlement == .pro
        state.currentProductID = status.productID
        return .none

      case .productsLoaded(let products):
        state.products = products
        if state.selectedProductID == nil {
          // 플랜 변경이면 지금 쓰고 있는 플랜을 그대로 보여준다 — 아무것도 안 눌러도 "다른 플랜"을
          // 고르라는 화면인지 알 수 있어야 한다. 신규 가입이면 1개월(가장 짧은 구독, 정렬 기준 첫 항목)을 기본값으로 둔다.
          state.selectedProductID = state.currentProductID ?? products.first?.id
        }
        return .none

      case .productsLoadFailed:
        state.errorMessage = String.module("Couldn't load subscription plans. Check your connection and try again.")
        return .none

      case .didSelectProduct(let id):
        state.selectedProductID = id
        return .none

      case .didTapSubscribe:
        guard let productID = state.selectedProduct?.id else { return .none }
        state.isPurchasing = true
        state.errorMessage = nil
        return .run { send in
          do {
            let result = try await purchaseClient.purchase(productID: productID)
            switch result {
            case .success:
              await send(.purchaseSucceeded)
            case .userCancelled:
              await send(.purchaseCancelled)
            case .pending:
              await send(.purchasePending)
            }
          } catch {
            await send(.purchaseFailed)
          }
        }

      case .purchaseSucceeded:
        state.isPurchasing = false
        return .send(.delegate(.didFinish))

      case .purchaseCancelled:
        // 오류가 아니라 시트가 조용히 남아있는 경로다. 알럿을 띄우지 않는다.
        state.isPurchasing = false
        return .none

      case .purchasePending:
        state.isPurchasing = false
        state.errorMessage = String.module("Your purchase is pending approval.")
        return .none

      case .purchaseFailed:
        state.isPurchasing = false
        state.errorMessage = String.module("Purchase failed. Please try again.")
        return .none

      case .didTapRestore:
        state.isRestoring = true
        state.errorMessage = nil
        return .run { send in
          do {
            try await purchaseClient.restore()
            await send(.restoreSucceeded)
          } catch {
            await send(.restoreFailed)
          }
        }

      case .restoreSucceeded:
        state.isRestoring = false
        return .send(.delegate(.didFinish))

      case .restoreFailed:
        state.isRestoring = false
        state.errorMessage = String.module("Couldn't restore your purchase. Please try again.")
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
