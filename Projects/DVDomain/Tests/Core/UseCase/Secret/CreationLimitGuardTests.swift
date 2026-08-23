// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

/// 판정과 저장 사이에 다른 생성이 끼어들어도 한도를 넘기지 않는지 확인한다.
///
/// 판정(`canCreate…`)은 통과시키고 저장소만 이미 한도에 차 있는 상태로 만든다. 판정 시점과 저장 시점 사이에 다른 요청이 자리를 채운 상황과 같다.
@Suite("생성 한도 최종 방어선")
struct CreationLimitGuardTests {

    @Test("판정을 통과해도 저장 시점에 한도가 차 있으면 Secret 생성이 limitReached로 막힌다")
    func secretCreationBlockedAtPersistence() async throws {
        let repo = InMemorySecretRepository()
        for index in 0..<EntitlementLimits.maxSecrets {
            _ = try await repo.create(SecretFixture.make(id: UUID(), name: "기존 \(index)"), projectIDs: [])
        }

        let sut = CreateSecretUseCaseImpl(
            repository: repo,
            cryptoService: FakeSecretCryptoService(),
            entitlementUseCase: StubEntitlementUseCase(entitlement: .free, canCreateSecret: true)
        )

        await #expect(throws: EntitlementError.limitReached) {
            _ = try await sut.execute(
                draft: SecretFixture.draft(name: "한도 초과"),
                payload: APIKeyPayload(value: "sk_test_123"),
                projectIDs: []
            )
        }
    }

    @Test("Pro는 저장소가 무료 한도를 넘겨도 Secret을 계속 만들 수 있다")
    func proIgnoresFreeLimit() async throws {
        let repo = InMemorySecretRepository()
        for index in 0..<EntitlementLimits.maxSecrets {
            _ = try await repo.create(SecretFixture.make(id: UUID(), name: "기존 \(index)"), projectIDs: [])
        }

        let sut = CreateSecretUseCaseImpl(
            repository: repo,
            cryptoService: FakeSecretCryptoService(),
            entitlementUseCase: StubEntitlementUseCase(entitlement: .pro)
        )

        let created = try await sut.execute(
            draft: SecretFixture.draft(name: "한도 밖"),
            payload: APIKeyPayload(value: "sk_test_123"),
            projectIDs: []
        )

        #expect(created.name == "한도 밖")
    }

    @Test("판정을 통과해도 저장 시점에 한도가 차 있으면 Project 생성이 limitReached로 막힌다")
    func projectCreationBlockedAtPersistence() async throws {
        let repo = InMemoryProjectRepository()
        for index in 0..<EntitlementLimits.maxProjects {
            _ = try await repo.create(
                Project(id: UUID(), name: "기존 \(index)", createdAt: Date(), updatedAt: Date())
            )
        }

        let sut = CreateProjectUseCaseImpl(
            repository: repo,
            entitlementUseCase: StubEntitlementUseCase(entitlement: .free, canCreateProject: true)
        )

        await #expect(throws: EntitlementError.limitReached) {
            _ = try await sut.execute(name: "한도 초과")
        }
    }
}
