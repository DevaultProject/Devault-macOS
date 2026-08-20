// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVCore
import DVDomain

/// SwiftData FetchDescriptor로 처리하기 애매한 조건을 Domain Secret 배열에서 후처리하는 필터.
/// searchText 매칭과, SwiftData `SortDescriptor`가 지원하지 않는 로케일 인식 이름 정렬을 담당한다.
enum InMemorySecretQueryFilter {
    static func apply(
        _ query: SecretQuery,
        to secrets: [DVDomain.Secret],
        referenceDate: Date = .now
    ) -> [DVDomain.Secret] {
        let search = SearchQuery(query.searchText)
        let filtered = secrets
            .filter { matchesSearch(search, secret: $0) }
            .filter { matchesExpiry(query.collection, secret: $0, referenceDate: referenceDate) }
        return applySortIfNeeded(filtered, sort: query.sort)
    }

    /// 쿼리당 한 번 만들어 시크릿마다 재사용하는 검색어. 정규화를 필터 루프 밖에 둔다.
    private struct SearchQuery {

        let text: String
        let date: SecretDateFormatter.SearchKeyword

        /// 검색어가 없거나 공백뿐이면 `nil` — 전체 통과와 같다.
        init?(_ raw: String?) {
            guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !trimmed.isEmpty
            else { return nil }

            text = trimmed
            date = SecretDateFormatter.SearchKeyword(trimmed)
        }
    }

    /// `.all`/`.liked`(Star)는 이미 만료된 Secret을 보여주지 않는다 — 만료된 항목은 Expired 탭에서만 보인다.
    private static func matchesExpiry(
        _ collection: SecretQuery.Collection,
        secret: DVDomain.Secret,
        referenceDate: Date
    ) -> Bool {
        switch collection {
        case .all, .liked:
            break
        case .notice, .expired, .deleted, .project:
            // `.notice`는 SwiftData predicate가 이미 "지나지 않음 + window 이내"를 전부 검사했다.
            return true
        }
        guard let expiresAt = secret.expiresAt else {
            return true
        }
        return expiresAt >= referenceDate
    }

    /// `Array.sorted`는 안정 정렬이라, SwiftData 단계의 updatedAt tie-break 순서가
    /// 동률(같은 이름, 같은 만료일 없음)일 때 그대로 유지된다.
    private static func applySortIfNeeded(
        _ secrets: [DVDomain.Secret],
        sort: SecretQuery.Sort
    ) -> [DVDomain.Secret] {
        switch sort.key {
        case .name:
            return sortedByName(secrets, direction: sort.direction)
        case .expiry:
            return sortedByExpiry(secrets, direction: sort.direction)
        case .time:
            // SwiftData `SortDescriptor(\.updatedAt)`로 이미 원하는 순서로 왔다.
            return secrets
        }
    }

    /// SwiftData `SortDescriptor(\.name)`는 Unicode 코드포인트 순서(대소문자 구분)로만 비교해
    /// 한국어·영어가 섞인 이름을 사람이 기대하는 순서로 정렬하지 못한다.
    /// `localizedStandardCompare`로 대소문자 무시·로케일 인식 비교를 적용한다.
    private static func sortedByName(
        _ secrets: [DVDomain.Secret],
        direction: SecretQuery.Sort.Direction
    ) -> [DVDomain.Secret] {
        secrets.sorted {
            let order = $0.name.localizedStandardCompare($1.name)
            switch direction {
            case .ascending: return order == .orderedAscending
            case .descending: return order == .orderedDescending
            }
        }
    }

    /// SwiftData `SortDescriptor`는 옵셔널을 `nil < .some`으로만 비교해, 오름차순에서
    /// 만료일 없는 Secret이 맨 앞에 온다. 방향과 무관하게 항상 뒤로 보내려면 SwiftData가
    /// 만들어준 순서를 무시하고 여기서 다시 정렬해야 한다.
    private static func sortedByExpiry(
        _ secrets: [DVDomain.Secret],
        direction: SecretQuery.Sort.Direction
    ) -> [DVDomain.Secret] {
        let withExpiry = secrets.filter { $0.expiresAt != nil }
        let withoutExpiry = secrets.filter { $0.expiresAt == nil }
        let sorted = withExpiry.sorted { lhs, rhs in
            guard let lhsExpiresAt = lhs.expiresAt, let rhsExpiresAt = rhs.expiresAt else {
                return false
            }
            switch direction {
            case .ascending: return lhsExpiresAt < rhsExpiresAt
            case .descending: return lhsExpiresAt > rhsExpiresAt
            }
        }
        return sorted + withoutExpiry
    }

    private static func matchesSearch(_ search: SearchQuery?, secret: DVDomain.Secret) -> Bool {
        guard let search else {
            return true
        }

        let textFields: [String?] = [
            secret.name,
            secret.secretType.rawValue,
            secret.subType?.rawValue,
            secret.service,
            secret.environment,
            secret.memo,
        ]

        // 텍스트가 먼저다 — 날짜 매칭은 시크릿마다 날짜를 새로 포맷하고, 이 필터는 컬렉션
        // 전체를 돈다(searchText가 SwiftData predicate에 없다).
        if textFields.contains(where: { $0?.localizedCaseInsensitiveContains(search.text) == true }) {
            return true
        }

        // `createdAt`은 목록에 표시되지 않지만 검색 대상에는 남아 있다.
        return SecretDateFormatter.matches(search.date, date: secret.createdAt)
            || SecretDateFormatter.matches(search.date, date: secret.updatedAt)
    }
}
