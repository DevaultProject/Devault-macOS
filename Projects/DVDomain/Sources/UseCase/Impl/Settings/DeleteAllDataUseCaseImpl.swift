// Copyright © 2026 Devault. All rights reserved

import Foundation

/// Secret/Project 리포지토리는 항목별 순차 삭제만 제공한다(단일 배치 삭제 API 없음) — 중간에
/// 실패하면 부분 삭제 상태로 남을 수 있으나, "전체 초기화"라는 동작 성격상 1차 배포에서는
/// 단순 반복 삭제로 충분하다고 판단했다. 원자성이 중요해지면 repository에 배치 삭제를 추가한다.
public struct DeleteAllDataUseCaseImpl: DeleteAllDataUseCase {
    private let secretRepository: any SecretRepository
    private let projectRepository: any ProjectRepository
    private let authenticateUseCase: any AuthenticateUseCase

    public init(
        secretRepository: any SecretRepository,
        projectRepository: any ProjectRepository,
        authenticateUseCase: any AuthenticateUseCase
    ) {
        self.secretRepository = secretRepository
        self.projectRepository = projectRepository
        self.authenticateUseCase = authenticateUseCase
    }

    public func execute() async throws {
        try await authenticateUseCase.authenticate(reason: "Delete all data")

        do {
            // .all은 deletedAt == nil인 항목만 반환하므로, 휴지통(.deleted)도 별도로 모아야 정말 전부 지워진다.
            let active = try await secretRepository.fetch(SecretQuery(collection: .all))
            let trashed = try await secretRepository.fetch(SecretQuery(collection: .deleted))
            for secret in active + trashed {
                try await secretRepository.delete(id: secret.id)
            }

            let projects = try await projectRepository.fetchAll()
            for project in projects {
                try await projectRepository.delete(id: project.id)
            }
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }
}
