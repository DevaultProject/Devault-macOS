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
            // 판정과 저장 사이에 정규화·중복 검사가 끼어 있어, 동시에 시작한 생성 둘이 같은 개수를 보고 나란히 통과할 수 있다. 저장소가 세기와 넣기를 한 번에 처리하며 최종 판정을 내린다.
            let limit = entitlementUseCase.current() == .free ? EntitlementLimits.maxProjects : Int.max
            guard let created = try await repository.create(project, withinTotalLimit: limit) else {
                throw EntitlementError.limitReached
            }
            return created
        } catch let error as EntitlementError {
            // 게이트 차단은 도메인 오류로 접지 않는다 — 접으면 호출부가 페이월을 띄울 근거를 잃는다.
            throw error
        } catch {
            throw ProjectUseCaseError.map(error)
        }
    }
}
