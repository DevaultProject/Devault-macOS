// Copyright © 2026 Devault. All rights reserved

/// 구독 상품 조회·구매·복원과 등급 판정 근거를 제공하는 서비스입니다.
///
/// 이 프로토콜은 **StoreKit 타입을 일절 노출하지 않는다.** DVDomain은 Foundation과 DVCore 외의 프레임워크를 import하지 않으며, `StoreKit.Product`·`StoreKit.Transaction`은 공개 이니셜라이저가 없어 테스트에서 만들 수 없다. 구현이 도메인 값 타입으로 옮겨 넘긴다.
public protocol PurchaseService: Sendable {

    /// 페이월에 표시할 구독 상품을 조회한다.
    /// - Returns: 스토어에서 확인된 상품 목록. 등록되지 않은 ID는 조용히 빠진다
    func products() async throws -> [SubscriptionProduct]

    /// 상품을 구매한다. 성공하면 트랜잭션을 완료 처리하고 등급 캐시를 갱신한다.
    /// - Parameter productID: 구매할 상품 ID
    /// - Returns: 구매 흐름의 결과
    func purchase(productID: String) async throws -> PurchaseResult

    /// 스토어에서 현재 권한을 다시 읽어 등급 캐시를 갱신한다. 앱 시작 시와 복원 직후에 호출한다.
    /// - Returns: 갱신된 등급
    @discardableResult
    func refreshEntitlement() async -> Entitlement

    /// 구독 설정 화면에 표시할 현재 상태를 조회한다. 게이트 판정에는 쓰지 않는다.
    /// - Returns: 등급과 갱신일을 담은 상태
    func subscriptionStatus() async -> SubscriptionStatus

    /// 기기를 바꾼 사용자를 위해 App Store와 구매 이력을 동기화한다.
    func restore() async throws

    /// 앱 수명 동안 트랜잭션 변경을 감시하며 등급 캐시를 갱신한다.
    ///
    /// **Composition Root가 앱 시작 시 한 번만 호출한다.** 화면 생명주기에 묶으면 화면이 사라질 때 리스너가 죽어 외부 갱신·환불·가족 공유 변경을 놓친다. 반환된 Task는 앱이 살아 있는 동안 유지한다.
    /// - Returns: 감시를 수행하는 Task
    func observeTransactionUpdates() -> Task<Void, Never>
}

/// 구매 흐름의 결과.
public enum PurchaseResult: Equatable, Sendable {

    /// 구매가 완료되어 권한이 부여됐다.
    case success

    /// 사용자가 구매를 취소했다. **오류가 아니므로 알럿을 띄우지 않는다.**
    case userCancelled

    /// 승인 대기 중이다(가족 공유의 구매 요청 등). 승인되면 `observeTransactionUpdates()`가 받는다.
    case pending
}
