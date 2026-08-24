// Copyright © 2026 Devault. All rights reserved

import Foundation
import StoreKitTest
import Testing

import DVDomain
@testable import DVData

/// `Devault.storekit`의 위치. 이 파일은 git으로 추적되지 않으므로(상품 식별자 포함) 없을 수 있다.
private let storeKitConfigURL: URL = {
    // Projects/Devault/Tests/Purchase/<this> → Projects/Devault/ → Devault.storekit
    var url = URL(fileURLWithPath: #filePath)
    for _ in 0..<3 { url.deleteLastPathComponent() }
    return url.appending(path: "Devault.storekit")
}()

private let hasStoreKitConfig = FileManager.default.fileExists(atPath: storeKitConfigURL.path)

/// StoreKit 로컬 테스트 스토어를 상대로 구매 흐름을 검증한다.
///
/// `Devault.storekit`이 없으면 전부 건너뛴다 — 그 파일은 팀에서 별도로 전달받아야 하며 저장소에 없다. `generate-storekit`으로 스킴에 붙이는 것과 같은 파일을 쓴다.
@Suite("PurchaseServiceImpl (StoreKit 로컬 스토어)", .enabled(if: hasStoreKitConfig, "Devault.storekit 없음"))
struct PurchaseServiceImplTests {

    private func makeSUT() -> (PurchaseServiceImpl, SettingsRepositoryImpl) {
        let suiteName = "PurchaseServiceImplTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = SettingsRepositoryImpl(defaults: defaults)
        return (PurchaseServiceImpl(settingsRepository: settings), settings)
    }

    private func makeSession() throws -> SKTestSession {
        let session = try SKTestSession(contentsOf: storeKitConfigURL)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        return session
    }

    @Test("등록된 구독 상품을 조회한다")
    func fetchesProducts() async throws {
        _ = try makeSession()
        let (sut, _) = makeSUT()

        let products = try await sut.products()

        #expect(products.count == SubscriptionProductID.all.count)
        #expect(Set(products.map(\.id)) == Set(SubscriptionProductID.all))
        // 가격은 스토어프론트마다 다르므로 값이 아니라 존재만 확인한다.
        #expect(products.first?.displayPrice.isEmpty == false)
    }

    @Test("상품은 기간이 짧은 것부터 정렬된다")
    func sortsProductsByPeriod() async throws {
        _ = try makeSession()
        let (sut, _) = makeSUT()

        let products = try await sut.products()

        #expect(products.map(\.periodInMonths) == [1, 3, 6, 12])
    }

    @Test("1개월 상품만 월 환산 가격이 없다")
    func omitsMonthlyEquivalentForMonthlyProduct() async throws {
        _ = try makeSession()
        let (sut, _) = makeSUT()

        let products = try await sut.products()
        let monthly = try #require(products.first { $0.periodInMonths == 1 })
        let others = products.filter { $0.periodInMonths > 1 }

        #expect(monthly.monthlyEquivalentPrice == nil)
        #expect(others.isEmpty == false)
        #expect(others.allSatisfy { $0.monthlyEquivalentPrice?.isEmpty == false })
    }

    @Test("구매 전에는 무료 등급이다")
    func freeBeforePurchase() async throws {
        _ = try makeSession()
        let (sut, settings) = makeSUT()

        let entitlement = await sut.refreshEntitlement()

        #expect(entitlement == .free)
        #expect(settings.cachedEntitlement() == .free)
    }

    @Test("구매하면 Pro로 올라가고 캐시에 반영된다")
    func upgradesAfterPurchase() async throws {
        _ = try makeSession()
        let (sut, settings) = makeSUT()

        let result = try await sut.purchase(productID: SubscriptionProductID.proMonthly)

        #expect(result == .success)
        #expect(settings.cachedEntitlement() == .pro)
    }

    @Test("같은 그룹 안에서 플랜을 바꿔도(crossgrade) 재조회 시 여전히 pro다")
    func staysProAfterCrossgradeThenFreshLookup() async throws {
        // 실제 버그 재현: 3개월을 사고 곧바로 6개월로 바꾼(crossgrade) 뒤, 앱을 새로 띄운 것처럼
        // refreshEntitlement()로 다시 물었을 때도 pro여야 한다. 재빌드 후 free로 잘못 읽히는
        // 현상이 정확히 이 순서에서 재현됐다.
        _ = try makeSession()
        let (sut, settings) = makeSUT()

        #expect(try await sut.purchase(productID: SubscriptionProductID.proMonthly) == .success)
        #expect(try await sut.purchase(productID: SubscriptionProductID.proQuarterly) == .success)

        // 여기서 캐시를 지워서, 방금 구매 성공 때 심어둔 캐시가 아니라 StoreKit 재조회 결과만으로
        // 판정하게 만든다 — 앱을 새로 띄운 상황과 동일하다.
        settings.setCachedEntitlement(.free)

        let entitlement = await sut.refreshEntitlement()

        #expect(entitlement == .pro)
        #expect(settings.cachedEntitlement() == .pro)
    }

    @Test("구독이 만료되면 무료로 내려간다")
    func downgradesAfterExpiration() async throws {
        let session = try makeSession()
        let (sut, settings) = makeSUT()

        #expect(try await sut.purchase(productID: SubscriptionProductID.proMonthly) == .success)

        try session.expireSubscription(productIdentifier: SubscriptionProductID.proMonthly)
        let entitlement = await sut.refreshEntitlement()

        #expect(entitlement == .free)
        #expect(settings.cachedEntitlement() == .free)
    }

    @Test("환불된 구독은 권한으로 치지 않는다")
    func ignoresRefundedTransaction() async throws {
        let session = try makeSession()
        let (sut, _) = makeSUT()

        #expect(try await sut.purchase(productID: SubscriptionProductID.proMonthly) == .success)
        let transactionID = UInt(session.allTransactions().first!.identifier)

        try session.refundTransaction(identifier: transactionID)
        let entitlement = await sut.refreshEntitlement()

        #expect(entitlement == .free)
    }

    @Test("구독 상태에 갱신일이 담긴다")
    func reportsRenewalDate() async throws {
        let session = try makeSession()
        let (sut, _) = makeSUT()

        #expect(try await sut.purchase(productID: SubscriptionProductID.proMonthly) == .success)
        let status = await sut.subscriptionStatus()

        // subscriptionStatus()는 currentEntitlements를 재조회해서 얻든, 구매 성공 시점에 이미
        // 캐시해 둔 값을 쓰든 항상 방금 구매한 트랜잭션의 실제 갱신일을 담고 있어야 한다.
        #expect(status.entitlement == .pro)
        #expect(status.renewsAt != nil)
    }

    @Test("트랜잭션 조회가 비어 있어도 등급 캐시가 pro면 무료로 표시하지 않는다")
    func trustsCacheWhenTransactionLookupIsEmpty() async throws {
        // 실제 구매 없이 캐시만 pro로 만든다 — 구매 직후 currentEntitlements가 아직 반영되기
        // 전인 순간을 재현한다.
        _ = try makeSession()
        let (sut, settings) = makeSUT()
        settings.setCachedEntitlement(.pro)

        let status = await sut.subscriptionStatus()

        #expect(status.entitlement == .pro)
    }

    @Test("복원할 구매가 없으면 무료로 유지되고 에러를 던지지 않는다")
    func restoreWithNothingToRestoreStaysFree() async throws {
        _ = try makeSession()
        let (sut, settings) = makeSUT()

        try await sut.restore()

        #expect(settings.cachedEntitlement() == .free)
    }
}
