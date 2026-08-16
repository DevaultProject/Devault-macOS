// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftData
import Testing

import DVDomain

@testable import DVData

/// `SecretQuery.Sort`의 6개 조합(time/expiry/name × ascending/descending)이 실제 SwiftData
/// fetch 결과에 반영되는지 검증한다. `SecretFetchDescriptorBuilder`(SwiftData 레벨 정렬)와
/// `InMemorySecretQueryFilter`(name·expiry 후처리 정렬)를 합친 최종 결과를 본다 —
/// 사용자가 실제로 관찰하는 순서가 이 둘의 조합이기 때문이다.
@Suite("Secret 정렬")
struct SecretSortingTests {

    // MARK: - time

    @Test("time 오름차순은 updatedAt이 오래된 순")
    func timeAscending() async throws {
        let repository = try await makeRepository()
        let old = try await repository.seed(name: "Old", updatedAt: .reference)
        let new = try await repository.seed(name: "New", updatedAt: .reference.addingTimeInterval(3600))

        let result = try await repository.fetch(SecretQuery(sort: .init(key: .time, direction: .ascending)))

        #expect(result.map(\.id) == [old.id, new.id])
    }

    @Test("time 내림차순은 updatedAt이 최신인 순 — 기존 recentlyAdded와 동일하다")
    func timeDescending() async throws {
        let repository = try await makeRepository()
        let old = try await repository.seed(name: "Old", updatedAt: .reference)
        let new = try await repository.seed(name: "New", updatedAt: .reference.addingTimeInterval(3600))

        let result = try await repository.fetch(SecretQuery(sort: .init(key: .time, direction: .descending)))

        #expect(result.map(\.id) == [new.id, old.id])
    }

    // MARK: - expiry

    @Test("expiry 오름차순은 만료가 가까운 순, 만료일 없는 항목은 맨 뒤로 간다")
    func expiryAscending() async throws {
        let repository = try await makeRepository()
        let soon = try await repository.seed(name: "Soon", expiresAt: .reference.addingTimeInterval(86_400))
        let later = try await repository.seed(name: "Later", expiresAt: .reference.addingTimeInterval(2 * 86_400))
        let never = try await repository.seed(name: "Never", expiresAt: nil)

        let result = try await repository.fetch(SecretQuery(sort: .init(key: .expiry, direction: .ascending)))

        #expect(result.map(\.id) == [soon.id, later.id, never.id])
    }

    @Test("expiry 내림차순은 만료가 먼 순, 만료일 없는 항목은 여전히 맨 뒤로 간다")
    func expiryDescending() async throws {
        let repository = try await makeRepository()
        let soon = try await repository.seed(name: "Soon", expiresAt: .reference.addingTimeInterval(86_400))
        let later = try await repository.seed(name: "Later", expiresAt: .reference.addingTimeInterval(2 * 86_400))
        let never = try await repository.seed(name: "Never", expiresAt: nil)

        let result = try await repository.fetch(SecretQuery(sort: .init(key: .expiry, direction: .descending)))

        #expect(result.map(\.id) == [later.id, soon.id, never.id])
    }

    // MARK: - name

    @Test("name 오름차순은 로케일 인식 오름차순(A→Z)")
    func nameAscending() async throws {
        let repository = try await makeRepository()
        let banana = try await repository.seed(name: "Banana")
        let apple = try await repository.seed(name: "Apple")

        let result = try await repository.fetch(SecretQuery(sort: .init(key: .name, direction: .ascending)))

        #expect(result.map(\.id) == [apple.id, banana.id])
    }

    @Test("name 내림차순은 로케일 인식 내림차순(Z→A)")
    func nameDescending() async throws {
        let repository = try await makeRepository()
        let banana = try await repository.seed(name: "Banana")
        let apple = try await repository.seed(name: "Apple")

        let result = try await repository.fetch(SecretQuery(sort: .init(key: .name, direction: .descending)))

        #expect(result.map(\.id) == [banana.id, apple.id])
    }

    // MARK: - Helpers

    private func makeRepository() async throws -> SecretRepositoryImpl {
        let schema = Schema.appSchema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return SecretRepositoryImpl(modelContainer: container)
    }
}

private extension Date {
    static let reference = Date(timeIntervalSince1970: 1_800_000_000)
}

private extension SecretRepositoryImpl {
    /// 정렬 검증에 필요한 필드만 지정하고 나머지는 고정값으로 채운 Secret을 저장한다.
    @discardableResult
    func seed(
        name: String,
        updatedAt: Date = .reference,
        expiresAt: Date? = nil
    ) async throws -> DVDomain.Secret {
        let secret = DVDomain.Secret(
            id: UUID(),
            name: name,
            secretType: .apiKeyToken,
            expiresAt: expiresAt,
            createdAt: .reference,
            updatedAt: updatedAt,
            payload: DVDomain.SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
        )
        return try await create(secret)
    }
}
