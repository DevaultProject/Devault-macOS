// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData

import DVDomain

/// Domain의 SecretQuery를 SwiftData의 FetchDescriptor<SwiftDataModel.Secret>로 바꾸는 타입
enum SecretFetchDescriptorBuilder {
    static func make(from query: SecretQuery) -> FetchDescriptor<SwiftDataModel.Secret> {
        var descriptor = FetchDescriptor<SwiftDataModel.Secret>(
            predicate: predicate(from: query),
            sortBy: sortDescriptors(from: query.sort)
        )
        descriptor.includePendingChanges = true
        return descriptor
    }

    /// 개수 집계 전용 descriptor. 정렬은 개수에 영향이 없으므로 생략한다.
    ///
    /// `fetch` 경로는 SwiftData predicate를 통과한 뒤 `InMemorySecretQueryFilter`가 만료 항목을 한 번 더
    /// 걸러내지만, 개수 집계는 엔티티를 메모리로 올리지 않으므로 그 규칙을 predicate에 직접 넣어야
    /// 목록에 보이는 개수와 수치가 일치한다. (규칙 원본: `InMemorySecretQueryFilter.matchesExpiry`)
    ///
    /// `searchText`는 반영하지 않는다 — 사이드바 카운트는 검색어와 무관한 전체 개수를 보여준다.
    static func makeCountDescriptor(
        from query: SecretQuery,
        referenceDate: Date
    ) -> FetchDescriptor<SwiftDataModel.Secret> {
        var descriptor = FetchDescriptor<SwiftDataModel.Secret>(
            predicate: countPredicate(from: query, referenceDate: referenceDate)
        )
        descriptor.includePendingChanges = true
        return descriptor
    }

    /// `.all`/`.liked`만 만료 조건을 추가하고, 나머지는 목록용 predicate를 그대로 쓴다.
    ///
    /// 만료일이 없는 Secret은 "만료되지 않음"으로 취급해야 하는데, `#Predicate` 안에서는 강제 언래핑을
    /// 쓸 수 없다(SwiftData가 SQL로 번역하지 못해 fetch 시점에 실패한다). `?? .distantFuture`로 대체한다.
    private static func countPredicate(
        from query: SecretQuery,
        referenceDate: Date
    ) -> Predicate<SwiftDataModel.Secret> {
        let neverExpires = Date.distantFuture
        let hasSecretType = query.secretType != nil
        let secretType = query.secretType?.rawValue ?? ""
        let hasService = !(query.service?.isEmpty ?? true)
        let service = query.service ?? ""
        let hasEnvironment = !(query.environment?.isEmpty ?? true)
        let environment = query.environment ?? ""

        switch query.collection {
        case .all:
            return #Predicate<SwiftDataModel.Secret> { secret in
                secret.deletedAt == nil &&
                (secret.expiresAt ?? neverExpires) >= referenceDate &&
                (!hasSecretType || secret.secretType == secretType) &&
                (!hasService || secret.service == service) &&
                (!hasEnvironment || secret.environment == environment)
            }
        case .liked:
            return #Predicate<SwiftDataModel.Secret> { secret in
                secret.deletedAt == nil &&
                secret.liked &&
                (secret.expiresAt ?? neverExpires) >= referenceDate &&
                (!hasSecretType || secret.secretType == secretType) &&
                (!hasService || secret.service == service) &&
                (!hasEnvironment || secret.environment == environment)
            }
        case .expired, .deleted, .project:
            return predicate(from: query)
        }
    }

    private static func predicate(from query: SecretQuery) -> Predicate<SwiftDataModel.Secret> {
        let hasSecretType = query.secretType != nil
        let secretType = query.secretType?.rawValue ?? ""
        let hasService = !(query.service?.isEmpty ?? true)
        let service = query.service ?? ""
        let hasEnvironment = !(query.environment?.isEmpty ?? true)
        let environment = query.environment ?? ""

        switch query.collection {
        case .all:
            return #Predicate<SwiftDataModel.Secret> { secret in
                secret.deletedAt == nil &&
                (!hasSecretType || secret.secretType == secretType) &&
                (!hasService || secret.service == service) &&
                (!hasEnvironment || secret.environment == environment)
            }
        case .liked:
            return #Predicate<SwiftDataModel.Secret> { secret in
                secret.deletedAt == nil &&
                secret.liked &&
                (!hasSecretType || secret.secretType == secretType) &&
                (!hasService || secret.service == service) &&
                (!hasEnvironment || secret.environment == environment)
            }
        case let .expired(referenceDate):
            // 만료일이 없으면 `.distantFuture`로 치환 — referenceDate보다 항상 크므로 자연히 제외된다.
            // (강제 언래핑은 SwiftData가 SQL로 번역하지 못해 fetch 시점에 실패한다)
            let neverExpires = Date.distantFuture
            return #Predicate<SwiftDataModel.Secret> { secret in
                secret.deletedAt == nil &&
                (secret.expiresAt ?? neverExpires) < referenceDate &&
                (!hasSecretType || secret.secretType == secretType) &&
                (!hasService || secret.service == service) &&
                (!hasEnvironment || secret.environment == environment)
            }
        case .deleted:
            return #Predicate<SwiftDataModel.Secret> { secret in
                secret.deletedAt != nil &&
                (!hasSecretType || secret.secretType == secretType) &&
                (!hasService || secret.service == service) &&
                (!hasEnvironment || secret.environment == environment)
            }
        case let .project(projectID):
            return #Predicate<SwiftDataModel.Secret> { secret in
                secret.deletedAt == nil &&
                secret.projectLinks?.contains { link in
                    link.projectID == projectID
                } == true &&
                (!hasSecretType || secret.secretType == secretType) &&
                (!hasService || secret.service == service) &&
                (!hasEnvironment || secret.environment == environment)
            }
        }
    }

    private static func sortDescriptors(
        from sort: SecretQuery.Sort
    ) -> [SortDescriptor<SwiftDataModel.Secret>] {
        switch sort {
        case .recentlyAdded:
            return [
                SortDescriptor(\.createdAt, order: .reverse),
                SortDescriptor(\.updatedAt, order: .reverse),
            ]
        case .oldestFirst:
            return [
                SortDescriptor(\.createdAt, order: .forward),
                SortDescriptor(\.updatedAt, order: .forward),
            ]
        case .expiringSoon:
            return [
                SortDescriptor(\.expiresAt, order: .forward),
                SortDescriptor(\.updatedAt, order: .reverse),
            ]
        case .nameAscending:
            return [
                SortDescriptor(\.name, order: .forward),
                SortDescriptor(\.updatedAt, order: .reverse),
            ]
        case .nameDescending:
            return [
                SortDescriptor(\.name, order: .reverse),
                SortDescriptor(\.updatedAt, order: .reverse),
            ]
        }
    }
}
