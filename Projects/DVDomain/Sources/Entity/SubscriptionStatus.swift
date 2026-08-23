// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 구독 설정 화면에 표시할 현재 구독 상태.
///
/// 게이트 판정에는 쓰지 않는다 — 그쪽은 ``Entitlement``만 본다. 이 타입은 **설정 > 구독 화면 한 곳**을 위해 존재한다.
public struct SubscriptionStatus: Equatable, Sendable {

    /// 현재 등급.
    public let entitlement: Entitlement

    /// 현재 구독 중인 상품 ID. 무료면 nil.
    ///
    /// **페이월이 "같은 플랜"과 "다른 플랜"을 구분하는 유일한 근거다.** 이게 없으면 이미 쓰고 있는
    /// 플랜을 다시 선택해도 변경 버튼이 활성화된다.
    public let productID: String?

    /// 다음 갱신(또는 만료) 시각. 무료이거나 StoreKit이 값을 주지 않으면 nil.
    public let renewsAt: Date?

    /// 사용자가 자동 갱신을 꺼둔 상태인지. 켜져 있으면 `renewsAt`에 갱신되고, 꺼져 있으면 그때 만료된다.
    public let willAutoRenew: Bool

    public init(
        entitlement: Entitlement,
        productID: String? = nil,
        renewsAt: Date? = nil,
        willAutoRenew: Bool = false
    ) {
        self.entitlement = entitlement
        self.productID = productID
        self.renewsAt = renewsAt
        self.willAutoRenew = willAutoRenew
    }

    /// 구독 이력이 없는 기본 상태.
    public static let free = SubscriptionStatus(entitlement: .free)
}
