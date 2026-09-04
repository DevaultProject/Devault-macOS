// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Testing

@testable import DVPresentation

@MainActor
@Suite("DevaultProPaywallFeature")
struct DevaultProPaywallFeatureTests {

  private let monthly = SubscriptionProduct(
    id: "pro.monthly", displayName: "1개월", displayPrice: "₩4,900", periodInMonths: 1
  )
  private let yearly = SubscriptionProduct(
    id: "pro.yearly", displayName: "1년", displayPrice: "₩39,000", periodInMonths: 12, monthlyEquivalentPrice: "₩3,250"
  )

  @Test("task는 신규 가입이면 상태·상품을 읽고 가장 짧은 구독을 기본 선택한다")
  func taskLoadsStatusAndProductsForNewSubscriber() async {
    let store = TestStore(initialState: DevaultProPaywallFeature.State()) {
      DevaultProPaywallFeature()
    } withDependencies: {
      $0.purchaseClient.subscriptionStatus = { .free }
      $0.purchaseClient.products = { [monthly, yearly] }
    }

    await store.send(.task)
    await store.receive(.statusLoaded(.free))
    await store.receive(.productsLoaded([monthly, yearly])) {
      $0.products = [monthly, yearly]
      $0.selectedProductID = monthly.id
    }
  }

  @Test("이미 구독 중이면 변경 모드로 전환되고 현재 플랜이 기본 선택된다")
  func taskLoadsChangingPlanStateForExistingSubscriber() async {
    let status = SubscriptionStatus(entitlement: .pro, productID: yearly.id)
    let store = TestStore(initialState: DevaultProPaywallFeature.State()) {
      DevaultProPaywallFeature()
    } withDependencies: {
      $0.purchaseClient.subscriptionStatus = { status }
      $0.purchaseClient.products = { [monthly, yearly] }
    }

    await store.send(.task)
    await store.receive(.statusLoaded(status)) {
      $0.isChangingPlan = true
      $0.currentProductID = yearly.id
    }
    await store.receive(.productsLoaded([monthly, yearly])) {
      $0.products = [monthly, yearly]
      $0.selectedProductID = yearly.id
    }
  }

  @Test("변경 예약이 있으면 예약된 플랜을 기본 선택하고, 그 플랜 재선택은 변경으로 치지 않는다")
  func pendingPlanChangeDefaultsToRenewalPlan() async {
    // 현재 1개월, 다음 갱신부터 1년으로 바꿔둔 상태.
    let status = SubscriptionStatus(
      entitlement: .pro, productID: monthly.id, willAutoRenew: true, renewalProductID: yearly.id
    )
    let store = TestStore(initialState: DevaultProPaywallFeature.State()) {
      DevaultProPaywallFeature()
    } withDependencies: {
      $0.purchaseClient.subscriptionStatus = { status }
      $0.purchaseClient.products = { [monthly, yearly] }
    }

    await store.send(.task)
    await store.receive(.statusLoaded(status)) {
      $0.isChangingPlan = true
      $0.currentProductID = monthly.id
      $0.renewalProductID = yearly.id
    }
    await store.receive(.productsLoaded([monthly, yearly])) {
      $0.products = [monthly, yearly]
      $0.selectedProductID = yearly.id  // 예약 플랜(1년)이 기본 선택
    }
    // 예약된 플랜을 그대로 고르면 변경이 아니다.
    #expect(store.state.isSelectingCurrentPlan)
    // 현재 활성(1개월)을 고르면 예약 취소 = 변경이 성립한다.
    await store.send(.didSelectProduct(monthly.id)) {
      $0.selectedProductID = monthly.id
    }
    #expect(store.state.isSelectingCurrentPlan == false)
  }

  @Test("상품 조회에 실패하면 에러 문구를 보여준다")
  func taskFailsToLoadProducts() async {
    let store = TestStore(initialState: DevaultProPaywallFeature.State()) {
      DevaultProPaywallFeature()
    } withDependencies: {
      $0.purchaseClient.subscriptionStatus = { .free }
      $0.purchaseClient.products = { throw PurchaseError.storeUnavailable }
    }

    await store.send(.task)
    await store.receive(.statusLoaded(.free))
    await store.receive(.productsLoadFailed) {
      $0.errorMessage = String.module("Couldn't load subscription plans. Check your connection and try again.")
    }
  }

  @Test("구매가 성공하면 delegate로 부모에게 알린다")
  func purchaseSucceeds() async {
    var state = DevaultProPaywallFeature.State()
    state.products = [monthly]
    state.selectedProductID = monthly.id

    let store = TestStore(initialState: state) {
      DevaultProPaywallFeature()
    } withDependencies: {
      $0.purchaseClient.purchase = { _ in .success }
    }

    await store.send(.didTapSubscribe) {
      $0.isPurchasing = true
    }
    await store.receive(.purchaseSucceeded) {
      $0.isPurchasing = false
    }
    await store.receive(.delegate(.didFinish))
  }

  @Test("사용자가 구매를 취소하면 에러 없이 조용히 끝난다")
  func purchaseCancelledShowsNoError() async {
    var state = DevaultProPaywallFeature.State()
    state.products = [monthly]
    state.selectedProductID = monthly.id

    let store = TestStore(initialState: state) {
      DevaultProPaywallFeature()
    } withDependencies: {
      $0.purchaseClient.purchase = { _ in .userCancelled }
    }

    await store.send(.didTapSubscribe) {
      $0.isPurchasing = true
    }
    await store.receive(.purchaseCancelled) {
      $0.isPurchasing = false
    }
  }

  @Test("구매가 실패하면 에러 문구를 보여준다")
  func purchaseFailsShowsError() async {
    var state = DevaultProPaywallFeature.State()
    state.products = [monthly]
    state.selectedProductID = monthly.id

    let store = TestStore(initialState: state) {
      DevaultProPaywallFeature()
    } withDependencies: {
      $0.purchaseClient.purchase = { _ in throw PurchaseError.unknown }
    }

    await store.send(.didTapSubscribe) {
      $0.isPurchasing = true
    }
    await store.receive(.purchaseFailed) {
      $0.isPurchasing = false
      $0.errorMessage = String.module("Purchase failed. Please try again.")
    }
  }

  @Test("복원이 성공하면 delegate로 부모에게 알린다")
  func restoreSucceeds() async {
    let store = TestStore(initialState: DevaultProPaywallFeature.State()) {
      DevaultProPaywallFeature()
    } withDependencies: {
      $0.purchaseClient.restore = {}
    }

    await store.send(.didTapRestore) {
      $0.isRestoring = true
    }
    await store.receive(.restoreSucceeded) {
      $0.isRestoring = false
    }
    await store.receive(.delegate(.didFinish))
  }

  @Test("복원이 실패하면 에러 문구를 보여준다")
  func restoreFailsShowsError() async {
    let store = TestStore(initialState: DevaultProPaywallFeature.State()) {
      DevaultProPaywallFeature()
    } withDependencies: {
      $0.purchaseClient.restore = { throw PurchaseError.storeUnavailable }
    }

    await store.send(.didTapRestore) {
      $0.isRestoring = true
    }
    await store.receive(.restoreFailed) {
      $0.isRestoring = false
      $0.errorMessage = String.module("Couldn't restore your purchase. Please try again.")
    }
  }

  @Test("이미 구독 중인 플랜을 선택하면 변경으로 취급하지 않는다")
  func selectingCurrentPlanIsNotAChange() {
    var state = DevaultProPaywallFeature.State()
    state.products = [monthly, yearly]
    state.currentProductID = monthly.id
    state.selectedProductID = monthly.id

    #expect(state.isSelectingCurrentPlan)
  }
}
