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

    @Test("Collection.notice는 referenceDate가 다르면 다르다")
    func collectionNoticeDistinguishesByReferenceDate() {
        let a = SecretQuery.Collection.notice(referenceDate: Date(timeIntervalSince1970: 0))
        let b = SecretQuery.Collection.notice(referenceDate: Date(timeIntervalSince1970: 1))

        #expect(a != b)
    }

    @Test("noticeWindowDays는 7일이다")
    func noticeWindowDaysIsSevenDays() {
        // upcomingWindow와의 일치 여부는 DVPresentation쪽 SecretExpiryStatusTests가 검증한다.
        #expect(SecretQuery.Collection.noticeWindowDays == 7)
    }

    @Test("noticeWindowEnd는 referenceDate를 noticeWindowDays만큼 민 시각이다")
    func noticeWindowEndShiftsReferenceDate() {
        let referenceDate = Date(timeIntervalSince1970: 0)

        let windowEnd = SecretQuery.Collection.noticeWindowEnd(from: referenceDate)

        let expected = referenceDate.addingTimeInterval(
            TimeInterval(SecretQuery.Collection.noticeWindowDays) * 86_400
        )
        #expect(windowEnd == expected)
    }

    @Test("expiringWindow는 기준일을 expiringSoonWindowDays만큼 민 expired 컬렉션을 만든다")
    func expiringWindowShiftsReferenceDate() {
        let today = Date(timeIntervalSince1970: 0)

        let collection = SecretQuery.Collection.expiringWindow(from: today)

        let expected = today.addingTimeInterval(
            TimeInterval(SecretQuery.Collection.expiringSoonWindowDays) * 86_400
        )
        #expect(collection == .expired(referenceDate: expected))
    }

    @Test("expiringWindow는 이미 만료된 것과 window 이내 예정을 함께 담는다")
    func expiringWindowCoversPastAndUpcoming() {
        let today = Date(timeIntervalSince1970: 0)
        let windowDays = TimeInterval(SecretQuery.Collection.expiringSoonWindowDays)

        guard case let .expired(windowEnd) = SecretQuery.Collection.expiringWindow(from: today) else {
            Issue.record("collection이 .expired가 아님")
            return
        }

        // predicate는 `expiresAt < windowEnd` 단일 비교이므로, 경계 안쪽만 포함되어야 한다.
        #expect(today.addingTimeInterval(-86_400) < windowEnd)
        #expect(today.addingTimeInterval((windowDays - 1) * 86_400) < windowEnd)
        #expect(today.addingTimeInterval((windowDays + 1) * 86_400) > windowEnd)
    }
}
