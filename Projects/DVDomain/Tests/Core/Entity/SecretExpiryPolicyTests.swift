// Copyright © 2026 Devault. All rights reserved

import Testing

@testable import DVDomain

@Suite("SecretExpiryPolicy")
struct SecretExpiryPolicyTests {

    @Test("단계별 기간은 critical < upcoming < listing 순으로 넓어진다")
    func windowsAreOrdered() {
        #expect(SecretExpiryPolicy.criticalWindowDays < SecretExpiryPolicy.upcomingWindowDays)
        #expect(SecretExpiryPolicy.upcomingWindowDays < SecretExpiryPolicy.listingWindowDays)
    }
}
