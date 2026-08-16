// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData
import Testing

import DVDomain

@testable import DVData

/// `.notice` predicate를 실제 in-memory `ModelContainer`로 fetch까지 실행해 검증한다.
@Suite("SecretFetchDescriptorBuilder")
struct SecretFetchDescriptorBuilderTests {
    private static let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema.appSchema,
            configurations: .init(isStoredInMemoryOnly: true)
        )
    }

    @discardableResult
    private func insertSecret(
        in context: ModelContext,
        name: String,
        expiresAt: Date?,
        deletedAt: Date? = nil
    ) -> SwiftDataModel.Secret {
        let secret = SwiftDataModel.Secret(
            name: name,
            secretType: "apiKeyToken",
            expiresAt: expiresAt,
            deletedAt: deletedAt
        )
        context.insert(secret)
        return secret
    }

    @Test(".notice predicate는 실제 ModelContainer에서 fetch 시점 오류 없이 실행된다")
    func noticePredicateExecutesAgainstRealModelContainer() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let referenceDate = Self.referenceDate

        insertSecret(in: context, name: "이미 만료", expiresAt: referenceDate.addingTimeInterval(-86_400))
        insertSecret(in: context, name: "정각 만료", expiresAt: referenceDate)
        insertSecret(in: context, name: "3일 후", expiresAt: referenceDate.addingTimeInterval(3 * 86_400))
        insertSecret(in: context, name: "정각 7일 후", expiresAt: SecretQuery.Collection.noticeWindowEnd(from: referenceDate))
        insertSecret(in: context, name: "10일 후", expiresAt: referenceDate.addingTimeInterval(10 * 86_400))
        insertSecret(in: context, name: "만료일 없음", expiresAt: nil)
        insertSecret(
            in: context,
            name: "삭제됨",
            expiresAt: referenceDate.addingTimeInterval(3 * 86_400),
            deletedAt: referenceDate
        )
        try context.save()

        let query = SecretQuery(collection: .notice(referenceDate: referenceDate))
        let descriptor = SecretFetchDescriptorBuilder.make(from: query)
        let fetched = try context.fetch(descriptor)

        let names = Set(fetched.map(\.name))
        #expect(names == ["정각 만료", "3일 후", "정각 7일 후"])
    }
}
