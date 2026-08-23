// Copyright © 2026 Devault. All rights reserved

import Foundation
import StoreKit

import DVCore
import DVDomain

/// StoreKit 2로 구독을 판매하고 권한을 확인하는 구현체.
///
/// 등급을 자체 필드에 들고 있지 않고 `SettingsRepository`의 캐시에 쓴다. 게이트 판정은 동기로 답해야 하는데 StoreKit 조회는 비동기라, 값을 UserDefaults에 두면 동기 읽기와 변경 스트림을 둘 다 공짜로 얻는다. 서비스가 상태를 갖지 않으므로 락도 actor도 필요 없다.
public struct PurchaseServiceImpl: PurchaseService {

    private let settingsRepository: any SettingsRepository
    private let productIDs: [String]

    public init(
        settingsRepository: any SettingsRepository,
        productIDs: [String] = SubscriptionProductID.all
    ) {
        self.settingsRepository = settingsRepository
        self.productIDs = productIDs
    }

    public func products() async throws -> [SubscriptionProduct] {
        do {
            let products = try await Product.products(for: productIDs)
            // 기간이 짧은 것부터 보여준다. 스토어는 순서를 보장하지 않는다.
            return products.compactMap(Self.subscriptionProduct(from:))
                .sorted { $0.periodInMonths < $1.periodInMonths }
        } catch {
            Log.error("[Purchase] 상품 조회 실패 — error: \(error)", category: .data)
            throw PurchaseError.storeUnavailable
        }
    }

    public func purchase(productID: String) async throws -> PurchaseResult {
        let products: [Product]
        do {
            products = try await Product.products(for: [productID])
        } catch {
            Log.error("[Purchase] 구매 전 상품 조회 실패 — error: \(error)", category: .data)
            throw PurchaseError.storeUnavailable
        }

        guard let product = products.first else {
            Log.error("[Purchase] 상품을 찾을 수 없음 — productID: \(productID)", category: .data)
            throw PurchaseError.productNotFound
        }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            Log.error("[Purchase] 구매 실패 — error: \(error)", category: .data)
            throw PurchaseError.storeUnavailable
        }

        switch result {
        case .success(let verification):
            // 검증에 실패한 트랜잭션은 **완료 처리하지 않는다.** finish는 권한을 부여했다는 신고이며,
            // 여기서 끝내면 변조된 트랜잭션이 사라져 재검토할 기회도 없어진다.
            guard case .verified(let transaction) = verification else {
                Log.error("[Purchase] 트랜잭션 검증 실패 — productID: \(productID)", category: .data)
                throw PurchaseError.verificationFailed
            }
            await transaction.finish()
            // 방금 검증한 트랜잭션이 손에 있으므로 `currentEntitlements`를 다시 묻지 않는다. 구매 직후에는
            // 스토어가 아직 반영 전이라 같은 트랜잭션을 미검증으로 돌려주는 순간이 있고, 그때 다시 물으면
            // 결제에 성공한 사용자가 잠시 무료로 떨어진다.
            settingsRepository.setCachedEntitlement(.pro)
            return .success

        case .userCancelled:
            return .userCancelled

        case .pending:
            return .pending

        @unknown default:
            Log.error("[Purchase] 알 수 없는 구매 결과 — productID: \(productID)", category: .data)
            throw PurchaseError.unknown
        }
    }

    @discardableResult
    public func refreshEntitlement() async -> Entitlement {
        let entitlement: Entitlement = await hasActiveSubscription() ? .pro : .free
        settingsRepository.setCachedEntitlement(entitlement)
        return entitlement
    }

    // StoreKit에도 `SubscriptionStatus`가 있어 한정이 필요하다. `Transaction`과 같은 이유다.
    public func subscriptionStatus() async -> DVDomain.SubscriptionStatus {
        guard let transaction = await activeTransaction() else { return .free }

        // 자동 갱신 여부는 트랜잭션이 아니라 구독 상태에 있다. 조회에 실패해도 등급·갱신일은 유효하므로 false로 둔다.
        let willAutoRenew = await willAutoRenew(for: transaction)
        return DVDomain.SubscriptionStatus(
            entitlement: .pro,
            renewsAt: transaction.expirationDate,
            willAutoRenew: willAutoRenew
        )
    }

    public func restore() async throws {
        do {
            try await AppStore.sync()
        } catch {
            Log.error("[Purchase] 구매 복원 실패 — error: \(error)", category: .data)
            throw PurchaseError.storeUnavailable
        }
        await refreshEntitlement()
    }

    public func observeTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [self] in
            // 앱이 꺼져 있는 동안 도착한 트랜잭션은 updates로 오지 않는다. 시작 시 한 번 걷어야
            // 승인 대기(pending)에서 승인된 구매나 다른 기기의 구매가 반영된다.
            await finishUnfinishedTransactions()
            await refreshEntitlement()

            for await verification in Transaction.updates {
                guard case .verified(let transaction) = verification else {
                    Log.error("[Purchase] 갱신 트랜잭션 검증 실패", category: .data)
                    continue
                }
                await transaction.finish()
                await refreshEntitlement()
            }
        }
    }
}

// MARK: - Mapping

extension PurchaseServiceImpl {

    /// `Product`를 도메인 값 타입으로 옮긴다. **기간을 읽지 못하면 제외한다** — 페이월이 설명할 수 없는 상품을 띄우느니 빼는 편이 낫다.
    private static func subscriptionProduct(from product: Product) -> SubscriptionProduct? {
        guard let months = periodInMonths(of: product) else {
            Log.error("[Purchase] 구독 기간을 읽지 못해 상품에서 제외 — productID: \(product.id)", category: .data)
            return nil
        }

        return SubscriptionProduct(
            id: product.id,
            displayName: product.displayName,
            displayPrice: product.displayPrice,
            periodInMonths: months,
            monthlyEquivalentPrice: monthlyEquivalentPrice(of: product, months: months)
        )
    }

    /// 구독 기간을 개월로 환산한다. 주·일 단위 구독은 쓰지 않으므로 nil을 돌려준다.
    private static func periodInMonths(of product: Product) -> Int? {
        guard let period = product.subscription?.subscriptionPeriod else { return nil }
        switch period.unit {
        case .month: return period.value
        case .year:  return period.value * 12
        case .day, .week: return nil
        @unknown default: return nil
        }
    }

    /// 월 환산 가격을 스토어의 통화 서식으로 만든다. 1개월 상품은 `displayPrice`와 같아지므로 nil이다.
    private static func monthlyEquivalentPrice(of product: Product, months: Int) -> String? {
        guard months > 1 else { return nil }
        return (product.price / Decimal(months)).formatted(product.priceFormatStyle)
    }
}

// MARK: - Private

extension PurchaseServiceImpl {

    /// 완료 처리되지 않은 트랜잭션을 걷는다. 남겨두면 StoreKit이 앱을 켤 때마다 다시 전달한다.
    private func finishUnfinishedTransactions() async {
        for await verification in Transaction.unfinished {
            guard case .verified(let transaction) = verification else { continue }
            await transaction.finish()
        }
    }

    /// 유효한 구독 권한이 있는지 확인한다.
    private func hasActiveSubscription() async -> Bool {
        await activeTransaction() != nil
    }

    /// 현재 유효한 구독 트랜잭션. 없으면 nil.
    ///
    /// `currentEntitlements`는 만료·해지된 구독을 이미 걸러주지만, **환불된 트랜잭션은 남을 수 있어** `revocationDate`를 직접 확인한다.
    private func activeTransaction() async -> StoreKit.Transaction? {
        for await verification in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verification else { continue }
            guard productIDs.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }
            return transaction
        }
        return nil
    }

    /// 다음 주기에 자동 갱신될 예정인지 확인한다.
    private func willAutoRenew(for transaction: StoreKit.Transaction) async -> Bool {
        guard let statuses = try? await transaction.subscriptionStatus,
              case .verified(let renewalInfo) = statuses.renewalInfo
        else {
            return false
        }
        return renewalInfo.willAutoRenew
    }
}
