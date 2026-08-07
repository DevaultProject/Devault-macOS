// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVData
import DVDomain
import DVPresentation
import Foundation

extension SecretClient: @retroactive DependencyKey {
    public static let liveValue: SecretClient = {
        let secretRepo = LiveRepositories.secret
        let projectRepo = LiveRepositories.project
        let cryptoService: any SecretCryptoService = SecretCryptoServiceImpl()
        let authService: any UserAuthenticationService = LocalUserAuthenticationServiceImpl()

        let fetchSecretUseCase: any FetchSecretUseCase = FetchSecretUseCaseImpl(
            repository: secretRepo,
            cryptoService: cryptoService,
            authenticationService: authService
        )
        let deleteSecretUseCase: any DeleteSecretUseCase = DeleteSecretUseCaseImpl(
            repository: secretRepo
        )
        let relationUseCase: any SecretProjectRelationUseCase = SecretProjectRelationUseCaseImpl(
            repository: secretRepo
        )
        let fetchProjectUseCase: any FetchProjectUseCase = FetchProjectUseCaseImpl(
            repository: projectRepo
        )
        let createProjectUseCase: any CreateProjectUseCase = CreateProjectUseCaseImpl(
            repository: projectRepo
        )

        return SecretClient(
            fetchByQuery: { query in
                try await fetchSecretUseCase.fetch(query: query)
            },
            softDelete: { id in
                try await deleteSecretUseCase.softDelete(id: id)
            },
            restore: { id in
                try await deleteSecretUseCase.restore(id: id)
            },
            permanentlyDelete: { id in
                try await deleteSecretUseCase.permanentlyDelete(id: id)
            },
            fetchProjects: {
                try await fetchProjectUseCase.fetchAll()
            },
            createProject: { name in
                try await createProjectUseCase.execute(name: name)
            },
            linkProject: { secretID, projectID in
                try await relationUseCase.link(secretID: secretID, projectID: projectID)
            }
        )
    }()
}
