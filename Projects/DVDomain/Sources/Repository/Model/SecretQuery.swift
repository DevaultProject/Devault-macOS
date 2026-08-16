// Copyright © 2026 Devault. All rights reserved

import Foundation

/// Secret 목록 조회 범위, 필터, 검색어, 정렬 조건을 표현합니다.
public struct SecretQuery: Equatable, Sendable {
    public var collection: Collection // 어디 탭/사이드 바 범위에서 볼 것인가
    public var secretType: SecretType? // 어떤 종류의 Secret인가
    public var service: String? // 어떤 서비스인가
    public var environment: String? // 어떤 실행 환경인가
    public var searchText: String? // 사용자가 입력한 텍스트 검색어
    public var sort: Sort // 어떤 순서로 볼 것인가

    public init(
        collection: Collection = .all,
        secretType: SecretType? = nil,
        service: String? = nil,
        environment: String? = nil,
        searchText: String? = nil,
        sort: Sort = .recentlyAdded
    ) {
        self.collection = collection
        self.secretType = secretType
        self.service = service
        self.environment = environment
        self.searchText = searchText
        self.sort = sort
    }
}

extension SecretQuery {
    public enum Collection: Equatable, Sendable {
        case all
        case liked
        /// 아직 안 지났지만 곧 지날 것만 모은 컬렉션. Expired(30일)의 부분집합이며, 이미 지난 건 제외한다.
        case notice(referenceDate: Date)
        case expired(referenceDate: Date)
        case deleted
        case project(id: UUID)

        /// Notice에 담을 "만료 임박" 기간(일). 목록 행 배지의 upcoming window(7일)와 같은 기준을 써야
        /// 사이드바 카드 숫자와 배지가 뜨는 시크릿 집합이 어긋나지 않는다.
        public static let noticeWindowDays = 7

        /// `referenceDate`로부터 `noticeWindowDays`만큼 민 시각.
        public static func noticeWindowEnd(from referenceDate: Date) -> Date {
            referenceDate.addingTimeInterval(TimeInterval(noticeWindowDays) * 86_400)
        }

        /// Expired 범위에 함께 담을 "만료 예정" 기간(일).
        public static let expiringSoonWindowDays = 30

        /// "이미 지남 + `expiringSoonWindowDays`일 이내 만료 예정"을 한 번에 담는 컬렉션.
        ///
        /// `expired` predicate는 `expiresAt < referenceDate` 단일 비교라, 기준일을 window만큼
        /// 미래로 밀어서 두 범위를 함께 가져온다. 목록 조회와 사이드바 개수 집계가 **같은 함수**를
        /// 써야 카드에 찍힌 숫자와 목록에 뜨는 개수가 어긋나지 않는다.
        /// - Parameter referenceDate: 실제 "오늘". window를 적용하기 전의 기준 시각
        public static func expiringWindow(from referenceDate: Date) -> Self {
            .expired(
                referenceDate: referenceDate.addingTimeInterval(
                    TimeInterval(expiringSoonWindowDays) * 86_400
                )
            )
        }
    }

    /// 정렬 기준(`key`)과 방향(`direction`)을 독립된 축으로 표현한다.
    ///
    /// 이전엔 `recentlyAdded`/`oldestFirst`/`expiringSoon`/`nameAscending`/`nameDescending`처럼
    /// 기준과 방향을 한 케이스에 묶어뒀다. 3기준 × 2방향 = 6개 조합 중 5개만 존재했고,
    /// 특히 "만료 내림차순(만료 늦은 순)"을 표현할 방법이 없었다.
    public struct Sort: Equatable, Sendable {
        public enum Key: Equatable, Sendable {
            /// `updatedAt` 기준. 목록 행에 표시되는 날짜와 같은 필드를 써야 사용자가 보는 순서와 정렬 기준이 일치한다.
            case time
            /// `expiresAt` 기준. 만료일이 없는 Secret은 방향과 무관하게 항상 뒤로 보낸다 — 소비처(정렬 구현부)의 책임.
            case expiry
            case name
        }

        public enum Direction: Equatable, Sendable {
            case ascending
            case descending
        }

        public var key: Key
        public var direction: Direction

        public init(key: Key, direction: Direction) {
            self.key = key
            self.direction = direction
        }

        /// 기존 `recentlyAdded`와 동일한 기본 정렬 — 최근 수정 순.
        public static let recentlyAdded = Sort(key: .time, direction: .descending)
    }
}
