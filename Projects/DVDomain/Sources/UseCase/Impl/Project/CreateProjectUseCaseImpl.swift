// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct CreateProjectUseCaseImpl: CreateProjectUseCase {
    private let repository: any ProjectRepository
    private let entitlementUseCase: any EntitlementUseCase
    private let idGenerator: @Sendable () -> UUID
    private let dateProvider: @Sendable () -> Date

    /// - Parameters:
    ///   - repository: Project 저장소
    ///   - entitlementUseCase: 무료 티어 한도 판정. **기본값을 두지 않는다** — 빠뜨리면 가드가 조용히 사라진다
    ///   - idGenerator: 새 Project의 ID
    ///   - dateProvider: 생성·수정 시각
    public init(
        repository: any ProjectRepository,
        entitlementUseCase: any EntitlementUseCase,
        idGenerator: @escaping @Sendable () -> UUID = { UUID() },
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.entitlementUseCase = entitlementUseCase
        self.idGenerator = idGenerator
        self.dateProvider = dateProvider
    }

    public func execute(name: String) async throws -> Project {
        // 판정 실패(저장소 오류)와 게이트 차단은 다른 것이다. 전자는 도메인 오류로 매핑하고, 후자만 EntitlementError로 내보내 호출부가 페이월을 띄우게 한다.
        let allowed: Bool
        do {
            allowed = try await entitlementUseCase.canCreateProject()
        } catch {
            throw ProjectUseCaseError.map(error)
        }
        guard allowed else { throw EntitlementError.limitReached }

        do {
            let normalizedName = try ProjectUseCaseHelper.normalizedName(name)
            let now = dateProvider()
            let project = Project(
                id: idGenerator(),
                name: normalizedName,
                createdAt: now,
                updatedAt: now
            )
            return try await repository.create(project)
        } catch {
            throw ProjectUseCaseError.map(error)
        }
    }
}
