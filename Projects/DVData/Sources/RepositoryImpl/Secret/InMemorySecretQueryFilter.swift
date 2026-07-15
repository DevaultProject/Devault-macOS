// Copyright © 2026 Devault. All rights reserved

import DVCore
import DVDomain
import Foundation

/// SwiftData FetchDescriptor로 처리하기 애매한 조건을 Domain Secret 배열에서 후처리하는 필터.
/// searchText 매칭과, SwiftData `SortDescriptor`가 지원하지 않는 로케일 인식 이름 정렬을 담당한다.
enum InMemorySecretQueryFilter {
    static func apply(_ query: SecretQuery, to secrets: [DVDomain.Secret]) -> [DVDomain.Secret] {
        let filtered = secrets
            .filter { matchesSearchText(query.searchText, secret: $0) }
            .filter { matchesExpiry(query.collection, secret: $0) }
        return sortedByNameIfNeeded(filtered, sort: query.sort)
    }

    /// `.all`/`.liked`(Star)는 이미 만료된 Secret을 보여주지 않는다 — 만료된 항목은 Expired 탭에서만 보인다.
    private static func matchesExpiry(_ collection: SecretQuery.Collection, secret: DVDomain.Secret) -> Bool {
        switch collection {
        case .all, .liked:
            break
        case .expired, .deleted, .project:
            return true
        }
        guard let expiresAt = secret.expiresAt else {
            return true
        }
        return expiresAt >= Date.now
    }

    /// SwiftData `SortDescriptor(\.name)`는 Unicode 코드포인트 순서(대소문자 구분)로만 비교해
    /// 한국어·영어가 섞인 이름을 사람이 기대하는 순서로 정렬하지 못한다.
    /// `localizedStandardCompare`로 대소문자 무시·로케일 인식 비교를 적용한다.
    /// `Array.sorted`는 안정 정렬이라, SwiftData 단계의 updatedAt tie-break 순서는 이름이 같을 때 그대로 유지된다.
    private static func sortedByNameIfNeeded(
        _ secrets: [DVDomain.Secret],
        sort: SecretQuery.Sort
    ) -> [DVDomain.Secret] {
        switch sort {
        case .nameAscending:
            return secrets.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .nameDescending:
            return secrets.sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }
        case .recentlyAdded, .oldestFirst, .expiringSoon:
            return secrets
        }
    }

    private static func matchesSearchText(_ searchText: String?, secret: DVDomain.Secret) -> Bool {
        guard let searchText else {
            return true
        }

        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            return true
        }

        let fields: [String?] = [
            secret.name,
            secret.secretType.rawValue,
            secret.subType?.rawValue,
            secret.service,
            secret.environment,
            secret.memo,
            SecretDateFormatter.string(from: secret.createdAt),
            SecretDateFormatter.string(from: secret.updatedAt),
        ]

        return fields.contains {
            $0?.localizedCaseInsensitiveContains(keyword) == true
        }
    }
}
