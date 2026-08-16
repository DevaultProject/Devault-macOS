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
        /// 만료 배지(critical/upcoming)가 붙는 대상만 모은 컬렉션. 이미 만료된 것은 제외한다 —
        /// Expired 탭이 "이미 지남"을 전담하므로 여기서까지 중복해 보여줄 이유가 없다.
        case notice(referenceDate: Date)
        case expired(referenceDate: Date)
        case deleted
        case project(id: UUID)

        /// Notice에 담을 "만료 임박" 기간(일). 목록 행 배지의 upcoming window(7일)와 같은 기준을 써야
        /// 사이드바 카드 숫자와 배지가 뜨는 시크릿 집합이 어긋나지 않는다.
        public static let noticeWindowDays = 7

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

    public enum Sort: Equatable, Sendable {
        case recentlyAdded
        case oldestFirst
        case expiringSoon
        case nameAscending
        case nameDescending
    }
}
