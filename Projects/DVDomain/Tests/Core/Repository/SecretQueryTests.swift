// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("SecretQuery")
struct SecretQueryTests {
    @Test("기본 생성자는 collection=all, sort=recentlyAdded로 초기화된다")
    func defaultInitUsesAllAndRecentlyAdded() {
        let query = SecretQuery()

        #expect(query.collection == .all)
        #expect(query.sort == .recentlyAdded)
        #expect(query.secretType == nil)
        #expect(query.service == nil)
        #expect(query.environment == nil)
        #expect(query.searchText == nil)
    }

    @Test("Collection.expired는 referenceDate가 다르면 다르다")
    func collectionExpiredDistinguishesByReferenceDate() {
        let a = SecretQuery.Collection.expired(referenceDate: Date(timeIntervalSince1970: 0))
        let b = SecretQuery.Collection.expired(referenceDate: Date(timeIntervalSince1970: 1))

        #expect(a != b)
    }
}
