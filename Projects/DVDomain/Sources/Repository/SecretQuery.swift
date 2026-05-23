// Copyright © 2026 Devault. All rights reserved

import Foundation

/// Secret 목록 조회 범위, 필터, 검색어, 정렬 조건을 표현합니다.
public struct SecretQuery: Equatable, Sendable {
    public var collection: Collection // 어디 탭/사이드 바 범위에서 볼 것인가
    public var secretType: String? // 어떤 종류의 Secret인가
    public var service: String? // 어떤 서비스인가
    public var environment: String? // 어떤 실행 환경인가
    public var searchText: String? // 사용자가 입력한 텍스트 검색어
    public var sort: Sort // 어떤 순서로 볼 것인가

    public init(
        collection: Collection = .all,
        secretType: String? = nil,
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

public extension SecretQuery {
    enum Collection: Equatable, Sendable {
        case all
        case liked
        case expired(referenceDate: Date)
        case deleted
        case project(id: UUID)
    }

    enum Sort: Equatable, Sendable {
        case recentlyAdded
        case oldestFirst
        case expiringSoon
        case nameAscending
        case nameDescending
    }
}
