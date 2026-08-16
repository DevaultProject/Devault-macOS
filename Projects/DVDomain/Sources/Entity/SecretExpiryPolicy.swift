// Copyright © 2026 Devault. All rights reserved

import Foundation

/// "만료가 임박했다"를 판단하는 기간 상수의 단일 소스.
///
/// 같은 개념(3일 / 7일 / 30일)이 배지 표시(`SecretExpiryStatus`), Expired 탭 섹션 분류
/// (`ExpiryBucket`), Expired 탭 쿼리 범위(`SecretQuery.Collection.expiringWindow`)에
/// 각각 필요하다. 값을 여기 하나로 모아두지 않으면 한 곳만 바뀌었을 때 나머지가 조용히
/// 어긋난다. 만료 알림(`ScheduleSecretExpiryNotificationsUseCaseImpl`)은 값이 같을 뿐
/// 의도적으로 여기 묶여있지 않다 — identifier 재구성 때문에 독립 상수를 쓴다.
///
/// 판정 로직(무엇을 배지로 보여줄지, 무엇을 섹션으로 나눌지)은 목적마다 달라 여기서
/// 통합하지 않는다. 여기서는 값만 소유한다.
public enum SecretExpiryPolicy {

    /// 즉시 조치가 필요한 단계로 볼 기간(일).
    public static let criticalWindowDays = 3

    /// 아직 조치할 시간이 있는 예고 단계로 볼 기간(일).
    public static let upcomingWindowDays = 7

    /// Expired 탭에 "만료 예정"으로 함께 보여줄 범위(일).
    public static let listingWindowDays = 30
}
