// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVData
import DVDomain
import DVPresentation

extension ProjectClient: @retroactive DependencyKey {
    public static let liveValue: ProjectClient = {
        let fetchUseCase: any FetchProjectUseCase = FetchProjectUseCaseImpl(
            repository: LiveRepositories.project
        )

        return ProjectClient(
            fetchProjects: {
                try await fetchUseCase.fetchAll()
            }
        )
    }()
}
