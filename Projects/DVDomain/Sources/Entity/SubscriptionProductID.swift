// Copyright © 2026 Devault. All rights reserved

/// App Store Connect에 등록한 구독 상품 ID의 단일 소스.
///
/// **이 문자열은 App Store Connect의 상품 ID와 정확히 일치해야 한다.** 어긋나면 `Product.products(for:)`가 빈 배열을 돌려주고, 페이월이 상품 없이 열린다 — 컴파일도 통과하고 크래시도 나지 않아 심사에서야 발견된다.
public enum SubscriptionProductID {

    /// 월간 구독. 현재 판매하는 유일한 상품이다.
    public static let proMonthly = "com.devault.app.pro.monthly"

    /// 페이월이 조회할 상품 목록. 연간 상품을 추가하면 **같은 구독 그룹**에 넣고 여기에 더한다 — 그룹이 다르면 StoreKit이 업그레이드·다운그레이드를 처리하지 못한다.
    public static let all = [proMonthly]
}
