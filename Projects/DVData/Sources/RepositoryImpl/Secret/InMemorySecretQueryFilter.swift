// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation

/// SwiftData FetchDescriptor로 처리하기 애매한 조건을 Domain Secret 배열에서 후처리하는 필터. 현재는 searchText만 담당
enum InMemorySecretQueryFilter {
    static func apply(_ query: SecretQuery, to secrets: [DVDomain.Secret]) -> [DVDomain.Secret] {
        secrets.filter { matchesSearchText(query.searchText, secret: $0) }
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
        ]

        return fields.contains {
            $0?.localizedCaseInsensitiveContains(keyword) == true
        }
    }
}
