// Copyright © 2026 Devault. All rights reserved

/// 페이월에 표시할 구독 상품.
///
/// **StoreKit의 `Product`를 도메인에 노출하지 않기 위한 변환 타입이다.** DVDomain은 Foundation과 DVCore 외의 프레임워크를 import하지 않으며, `StoreKit.Product`는 공개 이니셜라이저가 없어 테스트에서 만들 수 없다. DVData의 `PurchaseService` 구현이 `Product`를 읽어 이 타입으로 옮긴다.
public struct SubscriptionProduct: Equatable, Identifiable, Sendable {

    /// App Store Connect에 등록한 상품 ID. `id`로도 쓰인다.
    public let id: String

    /// 상품 이름. App Store Connect에 등록한 지역화 표시명이 그대로 온다.
    public let displayName: String

    /// 통화 기호와 지역 형식이 이미 적용된 가격 문자열(`Product.displayPrice`). **직접 포맷하지 않는다** — 통화·지역·자릿수 처리를 StoreKit에 맡긴다.
    public let displayPrice: String

    public init(id: String, displayName: String, displayPrice: String) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
    }
}
