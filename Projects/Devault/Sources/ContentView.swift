import DVData
import DVDomain
import DVPresentation
import SwiftUI

struct ContentView: View {
    private let secretRepository: SecretRepositoryImpl
    private let projectRepository: ProjectRepositoryImpl
    private let cryptoService = SecretCryptoServiceImpl()
    private let authenticationService = LocalUserAuthenticationServiceImpl()

    init(storage: LocalStorage) {
        self.secretRepository = SecretRepositoryImpl(modelContainer: storage.modelContainer)
        self.projectRepository = ProjectRepositoryImpl(modelContainer: storage.modelContainer)
    }

    var body: some View {
        ProjectSecretRelationDemoView(
            createProjectUseCase: CreateProjectUseCaseImpl(
                repository: projectRepository
            ),
            fetchProjectUseCase: FetchProjectUseCaseImpl(
                repository: projectRepository
            ),
            createSecretUseCase: CreateSecretUseCaseImpl(
                repository: secretRepository,
                cryptoService: cryptoService
            ),
            fetchSecretUseCase: FetchSecretUseCaseImpl(
                repository: secretRepository,
                cryptoService: cryptoService,
                authenticationService: authenticationService
            ),
            secretProjectRelationUseCase: SecretProjectRelationUseCaseImpl(
                repository: secretRepository
            )
        )
    }
}
