// Copyright © 2026 Devault. All rights reserved

/// 구독 구매·복원 과정에서 발생하는 오류.
public enum PurchaseError: Error, Equatable, Sendable {

    /// 요청한 상품 ID가 스토어에 없다. App Store Connect 등록 누락이거나 `SubscriptionProductID`와 어긋난 경우다.
    case productNotFound

    /// StoreKit이 트랜잭션 서명을 검증하지 못했다. 변조 가능성이 있으므로 **권한을 부여하지 않는다**.
    case verificationFailed

    /// 스토어에 접근하지 못했다. 재시도할 가치가 있는 유일한 오류다.
    case storeUnavailable

    /// 그 외 예기치 않은 오류.
    case unknown
}
