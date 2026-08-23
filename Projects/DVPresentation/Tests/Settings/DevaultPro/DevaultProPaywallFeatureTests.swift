// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Testing

@testable import DVPresentation

@MainActor
@Suite("DevaultProPaywallFeature")
struct DevaultProPaywallFeatureTests {

  private static let monthly = SubscriptionProduct(
    id: "pro.monthly", displayName: "1개월", displayPrice: "₩4,900", periodInMonths: 1
  )
  private static let yearly = SubscriptionProduct(
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
      $0.errorMessage = "Couldn't load subscription plans. Check your connection and try again."
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
      $0.errorMessage = "Purchase failed. Please try again."
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
      $0.errorMessage = "Couldn't restore your purchase. Please try again."
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
