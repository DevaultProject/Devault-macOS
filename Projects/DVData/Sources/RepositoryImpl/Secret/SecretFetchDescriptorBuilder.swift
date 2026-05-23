// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation
import SwiftData

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

    private static func predicate(from query: SecretQuery) -> Predicate<SwiftDataModel.Secret> {
        let hasSecretType = !(query.secretType?.isEmpty ?? true)
        let secretType = query.secretType ?? ""
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
            return #Predicate<SwiftDataModel.Secret> { secret in
                secret.deletedAt == nil &&
                secret.expiresAt != nil &&
                secret.expiresAt! < referenceDate &&
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
                secret.projectLinks.contains { link in
                    link.project.id == projectID
                } &&
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
