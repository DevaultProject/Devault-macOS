// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

import DVDesign

@testable import DVPresentation

@Suite("SecretExpiryStatus")
struct SecretExpiryStatusTests {

    /// 모든 케이스가 이 시각을 기준으로 판정된다. `.now`를 쓰면 경계 테스트가 실행 시점에 흔들린다.
    private static let now = Date(timeIntervalSince1970: 1_800_000_000)

    private static func status(daysFromNow days: Double) -> SecretExpiryStatus? {
        SecretExpiryStatus(
            expiresAt: now.addingTimeInterval(days * 86_400),
            now: now
        )
    }

    // MARK: - 만료일 없음

    @Test("만료일이 없으면 nil — 만료 개념이 없는 시크릿이다")
    func noExpiryDate() {
        #expect(SecretExpiryStatus(expiresAt: nil, now: Self.now) == nil)
    }

    // MARK: - critical (이미 만료 + 3일 이내)

    @Test("이미 만료된 경우 critical — 3일 이내와 구분하지 않는다")
    func alreadyExpiredIsCritical() {
        #expect(Self.status(daysFromNow: -30) == .critical)
        #expect(Self.status(daysFromNow: -1) == .critical)
    }

    @Test("정확히 지금 만료되는 경우 critical")
    func expiringExactlyNowIsCritical() {
        #expect(Self.status(daysFromNow: 0) == .critical)
    }

    @Test("3일 이내는 critical")
    func withinThreeDaysIsCritical() {
        #expect(Self.status(daysFromNow: 1) == .critical)
        #expect(Self.status(daysFromNow: 2.9) == .critical)
    }

    /// 경계 포함 여부를 고정한다 — `<=`가 `<`로 바뀌면 이 테스트가 깨진다.
    @Test("정확히 3일 경계는 critical에 포함된다")
    func exactlyThreeDaysIsCritical() {
        #expect(Self.status(daysFromNow: 3) == .critical)
    }

    // MARK: - upcoming (3일 초과 ~ 7일 이내)

    @Test("3일을 갓 넘기면 upcoming")
    func justOverThreeDaysIsUpcoming() {
        #expect(Self.status(daysFromNow: 3.1) == .upcoming)
    }

    @Test("7일 이내는 upcoming")
    func withinSevenDaysIsUpcoming() {
        #expect(Self.status(daysFromNow: 5) == .upcoming)
        #expect(Self.status(daysFromNow: 6.9) == .upcoming)
    }

    @Test("정확히 7일 경계는 upcoming에 포함된다")
    func exactlySevenDaysIsUpcoming() {
        #expect(Self.status(daysFromNow: 7) == .upcoming)
    }

    // MARK: - 표시 없음

    @Test("7일을 넘기면 nil — 아무 표시도 하지 않는다")
    func beyondSevenDaysIsNil() {
        #expect(Self.status(daysFromNow: 7.1) == nil)
        #expect(Self.status(daysFromNow: 365) == nil)
    }

    // MARK: - 표현 매핑

    @Test("critical은 danger, upcoming은 warning으로 강조된다")
    func emphasisMapping() {
        #expect(SecretExpiryStatus.critical.emphasis == DVExpiryEmphasis.danger)
        #expect(SecretExpiryStatus.upcoming.emphasis == DVExpiryEmphasis.warning)
    }

    // MARK: - 임계값 상수

    @Test("임계값은 3일 / 7일이다")
    func windowConstants() {
        #expect(SecretExpiryStatus.criticalWindow == 3 * 86_400)
        #expect(SecretExpiryStatus.upcomingWindow == 7 * 86_400)
    }
}
