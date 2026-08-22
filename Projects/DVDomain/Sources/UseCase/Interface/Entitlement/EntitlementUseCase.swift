// Copyright © 2026 Devault. All rights reserved

/// 무료 / Pro 게이트를 판정하는 **단일 지점**입니다.
///
/// 호출부는 개수를 세거나 등급을 비교하지 않는다 — 판정 결과만 묻는다. 각 Feature가 직접 세면 판정 근거가 바뀔 때 전부 뜯어야 하고, 화면마다 판정이 갈리는 버그가 난다.
///
/// **판정 실패는 게이트가 아니다.** `async throws` 메서드가 throw하면 저장소가 깨진 상태이므로 호출부는 **업그레이드 시트를 띄우지 말고** 일반 오류로 다뤄야 한다. 저장소 오류를 "구독하세요"로 바꿔 보여주면 결제해도 해결되지 않는다.
public protocol EntitlementUseCase: Sendable {

    /// 현재 등급을 반환한다.
    /// - Returns: 현재 등급
    func current() -> Entitlement

    /// 구독을 시작하면 현재 등급을 즉시 한 번 방출하고, 이후 등급이 바뀔 때마다 최신값을 방출한다. 즉시 방출하지 않으면 앱 시작 직후 등급을 모르는 구간이 생겨 게이트가 잘못 열린다.
    /// - Returns: 등급 스트림
    func stream() -> AsyncStream<Entitlement>

    /// 새 Secret을 만들 수 있는지 판정한다. 저장소 개수를 세므로 비용이 있다.
    /// - Returns: 생성 가능 여부
    func canCreateSecret() async throws -> Bool

    /// 새 Project를 만들 수 있는지 판정한다. 저장소 개수를 세므로 비용이 있다.
    /// - Returns: 생성 가능 여부
    func canCreateProject() async throws -> Bool

    /// Secret 수정 모드에 들어갈 수 있는지 판정한다.
    ///
    /// 보유 수가 한도를 **넘긴** 경우에만 false다(한도와 같으면 허용). 무료 사용자는 생성이 이미 막히므로 이 상태에 자연히 도달하지 않고, **Pro → 무료 다운그레이드에서만** 발생한다.
    /// - Returns: 수정 가능 여부
    func canEditSecrets() async throws -> Bool

    /// iCloud 동기화를 켤 수 있는지 판정한다. 등급만 보므로 비용이 없다.
    /// - Returns: 동기화 사용 가능 여부
    func canEnableICloudSync() -> Bool

    /// 만료 알림 시점을 여러 개 지정할 수 있는지 판정한다. 등급만 보므로 비용이 없다.
    /// - Returns: 다중 시점 사용 가능 여부
    func canUseMultipleExpiryAlertDays() -> Bool
}
