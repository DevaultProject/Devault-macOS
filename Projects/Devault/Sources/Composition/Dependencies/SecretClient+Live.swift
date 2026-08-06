// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVData
import DVDomain
import DVPresentation
import Foundation

extension SecretClient: @retroactive DependencyKey {
    public static let liveValue: SecretClient = {
        let container = LiveStorage.shared.modelContainer

        let secretRepo: any SecretRepository = SecretRepositoryImpl(modelContainer: container)
        let projectRepo: any ProjectRepository = ProjectRepositoryImpl(modelContainer: container)
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
                do {
                    return try await fetchSecretUseCase.fetch(query: query)
                } catch {
                    throw (error as? SecretUseCaseError) ?? .unexpected
                }
            },
            softDelete: { id in
                do {
                    return try await deleteSecretUseCase.softDelete(id: id)
                } catch {
                    throw (error as? SecretUseCaseError) ?? .unexpected
                }
            },
            restore: { id in
                do {
                    return try await deleteSecretUseCase.restore(id: id)
                } catch {
                    throw (error as? SecretUseCaseError) ?? .unexpected
                }
            },
            permanentlyDelete: { id in
                do {
                    try await deleteSecretUseCase.permanentlyDelete(id: id)
                } catch {
                    throw (error as? SecretUseCaseError) ?? .unexpected
                }
            },
            fetchProjects: {
                do {
                    return try await fetchProjectUseCase.fetchAll()
                } catch {
                    throw (error as? ProjectUseCaseError) ?? .unexpected
                }
            },
            createProject: { name in
                do {
                    return try await createProjectUseCase.execute(name: name)
                } catch {
                    throw (error as? ProjectUseCaseError) ?? .unexpected
                }
            },
            linkProject: { secretID, projectID in
                do {
                    try await relationUseCase.link(secretID: secretID, projectID: projectID)
                } catch {
                    throw (error as? SecretUseCaseError) ?? .unexpected
                }
            }
        )
    }()
}
