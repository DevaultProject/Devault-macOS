// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVData
import DVDomain
import DVPresentation

extension ProjectClient: @retroactive DependencyKey {
    public static let liveValue: ProjectClient = {
        let container = LiveStorage.shared.modelContainer
        let repo: any ProjectRepository = ProjectRepositoryImpl(modelContainer: container)
        let fetchUseCase: any FetchProjectUseCase = FetchProjectUseCaseImpl(repository: repo)

        return ProjectClient(
            fetchProjects: {
                do {
                    return try await fetchUseCase.fetchAll()
                } catch {
                    throw (error as? ProjectUseCaseError) ?? .unexpected
                }
            }
        )
    }()
}
