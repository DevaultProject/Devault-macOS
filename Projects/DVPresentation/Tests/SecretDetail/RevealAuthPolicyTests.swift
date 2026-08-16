// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVPresentation

@Suite("RevealAuthPolicy")
struct RevealAuthPolicyTests {

    private static let authorizedAt = Date(timeIntervalSince1970: 1_800_000_000)
    private static let policy = RevealAuthPolicy.default

    // MARK: - 인증 창 판정

    @Test("인증한 적이 없으면 창은 닫혀 있다")
    func neverAuthorized_isClosed() {
        #expect(Self.policy.isAuthorized(since: nil, now: Self.authorizedAt) == false)
    }

    @Test("ttl 안이면 열려 있다")
    func withinTTL_isOpen() {
        let now = Self.authorizedAt.addingTimeInterval(Self.policy.ttl - 1)
        #expect(Self.policy.isAuthorized(since: Self.authorizedAt, now: now))
    }

    @Test("ttl에 도달하면 닫힌다")
    func atTTL_isClosed() {
        let now = Self.authorizedAt.addingTimeInterval(Self.policy.ttl)
        #expect(Self.policy.isAuthorized(since: Self.authorizedAt, now: now) == false)
    }

    /// 시스템 시각이 뒤로 가면 간격이 음수가 된다. 음수는 언제나 ttl보다 작으므로
    /// 하한을 보지 않으면 창이 영원히 열린 것으로 판정된다 — 시계를 되돌리는 것만으로
    /// 만료가 무력화되면 안 된다.
    @Test("인증 시각이 미래면 닫힌 것으로 본다")
    func clockRolledBack_isClosed() {
        let now = Self.authorizedAt.addingTimeInterval(-60)
        #expect(Self.policy.isAuthorized(since: Self.authorizedAt, now: now) == false)
    }

    // MARK: - 무효화 이벤트

    @Test("기본 정책은 백그라운드 전환과 잠금 모두에서 창을 닫는다")
    func defaultPolicy_invalidatesOnBothEvents() {
        #expect(Self.policy.invalidates(on: .didEnterBackground))
        #expect(Self.policy.invalidates(on: .didLock))
    }

    @Test("무효화를 끄면 해당 이벤트는 창을 닫지 않는다")
    func disabledInvalidation_keepsWindowOpen() {
        let policy = RevealAuthPolicy(ttl: 180, invalidatesOnBackground: false, invalidatesOnLock: false)
        #expect(policy.invalidates(on: .didEnterBackground) == false)
        #expect(policy.invalidates(on: .didLock) == false)
    }
}
