// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVDesign
import DVDomain

/// 만료 임박 표기 정책의 단일 정의부 — 목록(`SecretListView`)과 조회(`DetailExpireDateFieldView`)가 함께 쓴다.
///
/// 두 화면이 임계값을 각자 들고 있으면 같은 시크릿이 목록에선 표시가 없고 조회에선 강조되는
/// 모순이 생긴다. 판정은 이 타입만 하고, 표현(아이콘·색)은 ``DVExpiryEmphasis``가 갖는다.
enum SecretExpiryStatus: Equatable {

    /// 이미 만료됐거나 ``criticalWindow`` 이내에 만료된다.
    ///
    /// 이미 지난 경우를 별도 단계로 두지 않는 것은 의도된 정책이다 —
    /// 사용자가 취해야 할 조치(갱신)가 같으므로 구분해서 보여줄 이유가 없다.
    case critical

    /// ``upcomingWindow`` 이내에 만료된다 — 아직 조치할 시간이 있는 예고 단계.
    case upcoming

    /// 하루를 고정 86,400초로 계산한다. 캘린더 일수(DST·타임존 경계)까지 따지지 않는 것은
    /// 목록의 `ExpiryBucket`과 같은 기준을 쓰기 위한 것이다.
    private static let secondsPerDay: TimeInterval = 86_400

    /// 남은 기간이 이 값 이하(이미 지나 음수인 경우 포함)면 ``critical``.
    /// 값 자체는 `SecretExpiryPolicy`가 소유한다 — 알림 스케줄·Expired 섹션 분류와 같은 기준을 쓴다.
    static let criticalWindow: TimeInterval = TimeInterval(SecretExpiryPolicy.criticalWindowDays) * secondsPerDay

    /// 남은 기간이 ``criticalWindow`` 초과이면서 이 값 이하면 ``upcoming``.
    /// Notice 탭(`SecretQuery.Collection.noticeWindowDays`)도 같은 값을 파생시켜 쓴다.
    static let upcomingWindow: TimeInterval = TimeInterval(SecretExpiryPolicy.upcomingWindowDays) * secondsPerDay

    /// 만료일로부터 상태를 산출한다. 만료일이 없거나 ``upcomingWindow``보다 멀면 `nil` — 아무 표시도 하지 않는다.
    ///
    /// - Parameters:
    ///   - expiresAt: 시크릿의 만료일. `nil`이면 만료 개념이 없는 시크릿이다.
    ///   - now: 판정 기준 시각. 테스트가 고정 시각을 주입한다.
    init?(expiresAt: Date?, now: Date = .now) {
        guard let expiresAt else { return nil }

        if expiresAt <= now.addingTimeInterval(Self.criticalWindow) {
            self = .critical
        } else if expiresAt <= now.addingTimeInterval(Self.upcomingWindow) {
            self = .upcoming
        } else {
            return nil
        }
    }

    /// 단계별 표현. 목록 행과 조회 필드가 이 하나를 통해 같은 아이콘·색을 얻는다.
    var emphasis: DVExpiryEmphasis {
        switch self {
        case .critical: return .danger
        case .upcoming: return .warning
        }
    }
}
