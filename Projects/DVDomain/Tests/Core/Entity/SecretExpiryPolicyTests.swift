// Copyright © 2026 Devault. All rights reserved

import Testing

@testable import DVDomain

@Suite("SecretExpiryPolicy")
struct SecretExpiryPolicyTests {

    /// 순서 검증만으로는 값이 바뀌어도 항상 통과해 회귀를 못 잡는다.
    @Test("criticalWindowDays는 3일이다")
    func criticalWindowDaysIsThree() {
        #expect(SecretExpiryPolicy.criticalWindowDays == 3)
    }

    @Test("upcomingWindowDays는 7일이다")
    func upcomingWindowDaysIsSeven() {
        #expect(SecretExpiryPolicy.upcomingWindowDays == 7)
    }

    @Test("단계별 기간은 critical < upcoming 순으로 넓어진다")
    func windowsAreOrdered() {
        #expect(SecretExpiryPolicy.criticalWindowDays < SecretExpiryPolicy.upcomingWindowDays)
    }
}
