// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Testing

@testable import DVPresentation

@MainActor
@Suite("DevaultProSettingsFeature")
struct DevaultProSettingsFeatureTests {

  private static let product = SubscriptionProduct(
    id: "pro.yearly", displayName: "1년", displayPrice: "₩39,000", periodInMonths: 12
  )

  @Test("task는 등급 스트림에서 상태와 플랜 이름을 읽어 온다")
  func taskLoadsStatusAndPlanName() async {
    let status = SubscriptionStatus(entitlement: .pro, productID: product.id)
    let store = TestStore(initialState: DevaultProSettingsFeature.State()) {
      DevaultProSettingsFeature()
    } withDependencies: {
      $0.entitlementClient.stream = {
        AsyncStream { continuation in
          continuation.yield(.pro)
          continuation.finish()
        }
      }
      $0.purchaseClient.subscriptionStatus = { status }
      $0.purchaseClient.products = { [product] }
      // 이 테스트는 상태·플랜 이름만 본다. 사용량 조회는 별도 테스트에서 검증한다.
      $0.secretClient.totalCountExcludingTrash = { throw CancellationError() }
    }

    await store.send(.task)
    await store.receive(.statusLoaded(status)) {
      $0.subscriptionStatus = status
    }
    await store.receive(.planNameLoaded(product.displayName)) {
      $0.currentPlanName = product.displayName
    }
  }

  @Test("task는 휴지통을 제외한 시크릿 사용량을 읽어 온다")
  func taskLoadsSecretUsageCount() async {
    let store = TestStore(initialState: DevaultProSettingsFeature.State()) {
      DevaultProSettingsFeature()
    } withDependencies: {
      $0.entitlementClient.stream = { .finished }
      $0.purchaseClient.subscriptionStatus = { .free }
      $0.secretClient.totalCountExcludingTrash = { 3 }
    }

    await store.send(.task)
    await store.receive(.secretCountLoaded(3)) {
      $0.secretCount = 3
    }
  }

  @Test("업그레이드를 누르면 페이월이 뜬다")
  func didTapUpgradePresentsPaywall() async {
    let store = TestStore(initialState: DevaultProSettingsFeature.State()) {
      DevaultProSettingsFeature()
    }

    await store.send(.didTapUpgrade) {
      $0.paywall = DevaultProPaywallFeature.State()
    }
  }

  @Test("페이월이 구매/복원을 마치면 닫히고 상태를 다시 읽는다")
  func paywallFinishDismissesAndReloads() async {
    var state = DevaultProSettingsFeature.State()
    state.paywall = DevaultProPaywallFeature.State()

    let store = TestStore(initialState: state) {
      DevaultProSettingsFeature()
    } withDependencies: {
      $0.purchaseClient.subscriptionStatus = { .free }
    }

    await store.send(.paywall(.presented(.delegate(.didFinish)))) {
      $0.paywall = nil
    }
    await store.receive(.statusLoaded(.free))
  }

  @Test("페이월을 그냥 닫아도 상태를 다시 읽는다 — 같은 등급 안에서 플랜만 바뀐 경우 스트림이 반응하지 않기 때문")
  func paywallDismissReloadsStatus() async {
    var state = DevaultProSettingsFeature.State()
    state.paywall = DevaultProPaywallFeature.State()

    let store = TestStore(initialState: state) {
      DevaultProSettingsFeature()
    } withDependencies: {
      $0.purchaseClient.subscriptionStatus = { .free }
    }

    await store.send(.paywall(.dismiss)) {
      $0.paywall = nil
    }
    await store.receive(.statusLoaded(.free))
  }

  @Test("구독 관리를 누르면 App Store 구독 관리 페이지를 연다")
  func didTapManageSubscriptionOpensAppStore() async {
    let opened = LockIsolated(false)
    let store = TestStore(initialState: DevaultProSettingsFeature.State()) {
      DevaultProSettingsFeature()
    } withDependencies: {
      $0.purchaseClient.openManageSubscriptions = { opened.setValue(true) }
    }

    await store.send(.didTapManageSubscription)
    #expect(opened.value)
  }
}
